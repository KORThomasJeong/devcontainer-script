#!/usr/bin/env bash
set -euo pipefail

# ── 색상 ────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERR]${NC}  $*"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODE_SERVER_NAME="devcontainer-ide"
CODE_SERVER_PORT=8080

declare -A SAMPLE_DIRS=(
  [01]="01-admin-dashboard"
  [02]="02-nextjs-web"
  [03]="03-ai-api"
  [04]="04-mobile-app"
  [05]="05-node-microservice"
  [06]="06-data-pipeline"
)
declare -A PG_PORTS=(
  [01]=5401 [02]=5402 [03]=5403 [04]=5404 [05]=5405 [06]=5406
)
declare -A REDIS_PORTS=(
  [01]=6301 [02]=6302 [03]=6303 [04]="" [05]=6305 [06]=6306
)

# ── 샘플 번호 해석 (1 → 01) ──────────────────────────────────────
resolve_sample() {
  local num
  num=$(printf '%02d' "${1#0}" 2>/dev/null) || error "잘못된 샘플 번호: $1"
  [[ -v SAMPLE_DIRS[$num] ]] || error "존재하지 않는 샘플: $num (01~06)"
  echo "$num"
}

compose_cmd() {
  local num="$1"; shift
  docker compose \
    -f "$SCRIPT_DIR/${SAMPLE_DIRS[$num]}/.devcontainer/docker-compose.yml" \
    --project-name "dc-${num}" "$@"
}

# ── code-server (공용 1개) ────────────────────────────────────────
cmd_ide() {
  if docker ps --format '{{.Names}}' | grep -q "^${CODE_SERVER_NAME}$"; then
    local host_ip
    host_ip=$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")
    success "code-server 이미 실행 중"
    echo -e "    로컬:  ${CYAN}http://localhost:${CODE_SERVER_PORT}${NC}"
    echo -e "    원격:  ${CYAN}http://${host_ip}:${CODE_SERVER_PORT}${NC}"
    return
  fi

  info "code-server 시작 중 (포트: ${CODE_SERVER_PORT})..."

  docker run -d \
    --name "${CODE_SERVER_NAME}" \
    --restart unless-stopped \
    -p "${CODE_SERVER_PORT}:8080" \
    -v "${SCRIPT_DIR}:/home/coder/workspace" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e PASSWORD="" \
    codercom/code-server:latest \
    --auth none \
    --bind-addr 0.0.0.0:8080 \
    /home/coder/workspace \
    > /dev/null

  info "Claude Code CLI 설치 중..."
  docker exec "${CODE_SERVER_NAME}" bash -c \
    "curl -fsSL https://nodejs.org/dist/v20.19.0/node-v20.19.0-linux-x64.tar.xz \
     | tar -xJ -C /usr/local --strip-components=1 2>/dev/null; \
     npm install -g @anthropic-ai/claude-code 2>/dev/null" &>/dev/null \
    && success "Claude Code CLI 설치됨" \
    || warn "Claude Code 설치 실패 — 터미널에서 수동 실행 가능"

  local host_ip
  host_ip=$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")
  echo ""
  success "code-server 준비 완료"
  echo -e "    로컬:  ${CYAN}http://localhost:${CODE_SERVER_PORT}${NC}"
  echo -e "    원격:  ${CYAN}http://${host_ip}:${CODE_SERVER_PORT}${NC}"
}

cmd_ide_stop() {
  if docker ps -a --format '{{.Names}}' | grep -q "^${CODE_SERVER_NAME}$"; then
    docker rm -f "${CODE_SERVER_NAME}" > /dev/null
    success "code-server 종료"
  else
    warn "code-server가 실행 중이지 않습니다"
  fi
}

# ── up ──────────────────────────────────────────────────────────
cmd_up() {
  [[ -n "${1:-}" ]] || error "샘플 번호를 입력하세요. 예: ./dc.sh up 1"
  local num
  num=$(resolve_sample "$1")

  echo ""
  echo -e "${BOLD}${CYAN}━━ dc up · ${SAMPLE_DIRS[$num]} ━━${NC}"

  info "DB / Redis 시작 중..."
  compose_cmd "$num" up -d --remove-orphans
  success "PostgreSQL :${PG_PORTS[$num]}  Redis :${REDIS_PORTS[$num]:-없음}"

  if command -v devcontainer &>/dev/null; then
    info "앱 컨테이너(devcontainer) 시작 중..."
    devcontainer up --workspace-folder "$SCRIPT_DIR/${SAMPLE_DIRS[$num]}" 2>/dev/null \
      && success "devcontainer 준비 완료" \
      || warn "devcontainer CLI 실패 — DB/Redis는 정상 실행 중"
  else
    warn "devcontainer CLI 없음. start.sh 를 먼저 실행하면 자동 설치됩니다."
  fi

  echo ""
  echo -e "${BOLD}  접속 정보${NC}"
  echo -e "  PostgreSQL  →  localhost:${PG_PORTS[$num]}  (dev / devpassword)"
  [[ -n "${REDIS_PORTS[$num]:-}" ]] && \
    echo -e "  Redis       →  localhost:${REDIS_PORTS[$num]}"
  echo -e "  IDE         →  ${CYAN}http://localhost:${CODE_SERVER_PORT}${NC}  (./dc.sh ide 로 시작)"
  echo ""
}

# ── down ────────────────────────────────────────────────────────
cmd_down() {
  [[ -n "${1:-}" ]] || error "샘플 번호를 입력하세요. 예: ./dc.sh down 1"
  local num
  num=$(resolve_sample "$1")

  echo ""
  echo -e "${BOLD}${CYAN}━━ dc down · ${SAMPLE_DIRS[$num]} ━━${NC}"
  compose_cmd "$num" down
  success "${SAMPLE_DIRS[$num]} 종료 완료"
}

# ── restart ──────────────────────────────────────────────────────
cmd_restart() {
  local num
  num=$(resolve_sample "${1:-}")
  cmd_down "$num"
  echo ""
  cmd_up "$num"
}

# ── status ───────────────────────────────────────────────────────
cmd_status() {
  local host_ip
  host_ip=$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")

  echo ""
  # code-server 상태
  if docker ps --format '{{.Names}}' | grep -q "^${CODE_SERVER_NAME}$"; then
    echo -e "  ${GREEN}● IDE (code-server)${NC}  http://localhost:${CODE_SERVER_PORT}  |  http://${host_ip}:${CODE_SERVER_PORT}"
  else
    echo -e "  ${RED}○ IDE (code-server)${NC}  중지됨  (./dc.sh ide 로 시작)"
  fi
  echo ""
  printf "${BOLD}  %-4s %-28s %-10s %-10s %-10s${NC}\n" "No." "샘플" "상태" "PG" "Redis"
  echo -e "  ──────────────────────────────────────────────────────"

  for num in 01 02 03 04 05 06; do
    local running=false
    docker ps --format '{{.Names}}' | grep -q "dc-${num}" && running=true

    local pg=":${PG_PORTS[$num]}"
    local redis="${REDIS_PORTS[$num]:+:${REDIS_PORTS[$num]}}"
    redis="${redis:----}"

    if $running; then
      printf "  ${GREEN}%-4s${NC} %-28s ${GREEN}%-10s${NC} %-10s %s\n" \
        "$num" "${SAMPLE_DIRS[$num]}" "● 실행중" "$pg" "$redis"
    else
      printf "  %-4s %-28s ${RED}%-10s${NC} %-10s %s\n" \
        "$num" "${SAMPLE_DIRS[$num]}" "○ 중지" "$pg" "$redis"
    fi
  done
  echo ""
}

# ── logs ─────────────────────────────────────────────────────────
cmd_logs() {
  [[ -n "${1:-}" ]] || error "샘플 번호를 입력하세요. 예: ./dc.sh logs 1"
  local num
  num=$(resolve_sample "$1")
  local service="${2:-}"
  info "${SAMPLE_DIRS[$num]} 로그 (Ctrl+C 중단)"
  compose_cmd "$num" logs -f --tail=50 $service
}

# ── ps ───────────────────────────────────────────────────────────
cmd_ps() {
  echo ""
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" \
    | grep -E "(NAMES|dc-|${CODE_SERVER_NAME})" \
    || echo "  실행 중인 컨테이너 없음"
  echo ""
}

# ── shell ────────────────────────────────────────────────────────
cmd_shell() {
  [[ -n "${1:-}" ]] || error "샘플 번호를 입력하세요. 예: ./dc.sh shell 1"
  local num
  num=$(resolve_sample "$1")

  if command -v devcontainer &>/dev/null; then
    devcontainer exec --workspace-folder "$SCRIPT_DIR/${SAMPLE_DIRS[$num]}" bash
  else
    docker exec -it "dc-${num}-app-1" bash 2>/dev/null \
      || error "실행 중인 앱 컨테이너가 없습니다. 먼저 ./dc.sh up $num"
  fi
}

# ── help ────────────────────────────────────────────────────────
cmd_help() {
  echo ""
  echo -e "${BOLD}${CYAN}  dc.sh — Devcontainer Manager${NC}"
  echo ""
  echo -e "  ${BOLD}사용법:${NC}  ./dc.sh <command> [번호]"
  echo ""
  echo -e "  ${BOLD}Commands:${NC}"
  echo -e "    ${GREEN}ide${NC}              브라우저 IDE (code-server) 시작  →  :8080"
  echo -e "    ${GREEN}ide stop${NC}         code-server 종료"
  echo -e "    ${GREEN}up${NC}    <번호>     샘플 DB + 앱 컨테이너 시작"
  echo -e "    ${GREEN}down${NC}  <번호>     종료"
  echo -e "    ${GREEN}restart${NC} <번호>   재시작"
  echo -e "    ${GREEN}status${NC}           전체 현황"
  echo -e "    ${GREEN}logs${NC}  <번호> [서비스]  로그 스트리밍"
  echo -e "    ${GREEN}ps${NC}               실행 컨테이너 목록"
  echo -e "    ${GREEN}shell${NC} <번호>     컨테이너 쉘 접속"
  echo ""
  echo -e "  ${BOLD}포트 배분${NC}"
  echo -e "    No.  샘플                  PG     Redis"
  echo -e "    01   admin-dashboard       5401   6301"
  echo -e "    02   nextjs-web            5402   6302"
  echo -e "    03   ai-api                5403   6303"
  echo -e "    04   mobile-app            5404   —"
  echo -e "    05   node-microservice     5405   6305"
  echo -e "    06   data-pipeline         5406   6306"
  echo -e "    IDE  code-server           —      :8080"
  echo ""
  echo -e "  ${BOLD}예시${NC}"
  echo -e "    ./dc.sh ide            # 브라우저 IDE 시작"
  echo -e "    ./dc.sh up 1           # 01 샘플 시작"
  echo -e "    ./dc.sh status         # 전체 현황"
  echo -e "    ./dc.sh logs 3 db      # 03 DB 로그"
  echo -e "    ./dc.sh down 1         # 01 종료"
  echo ""
}

# ── 메인 ────────────────────────────────────────────────────────
main() {
  local cmd="${1:-help}"; shift || true

  case "$cmd" in
    ide)     [[ "${1:-}" == "stop" ]] && cmd_ide_stop || cmd_ide ;;
    up)      cmd_up "$@" ;;
    down)    cmd_down "$@" ;;
    restart) cmd_restart "$@" ;;
    status)  cmd_status ;;
    logs)    cmd_logs "$@" ;;
    ps)      cmd_ps ;;
    shell)   cmd_shell "$@" ;;
    help|--help|-h) cmd_help ;;
    *) error "알 수 없는 명령어: $cmd  (./dc.sh help 참고)" ;;
  esac
}

main "$@"
