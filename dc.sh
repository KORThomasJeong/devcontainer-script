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

# ── lookup 함수 (declare -A 대신 case 사용, bash 3.2 호환) ──────
sample_dir() {
  case "$1" in
    01) echo "01-admin-dashboard" ;;
    02) echo "02-nextjs-web" ;;
    03) echo "03-ai-api" ;;
    04) echo "04-mobile-app" ;;
    05) echo "05-node-microservice" ;;
    06) echo "06-data-pipeline" ;;
    *) echo "" ;;
  esac
}

pg_port() {
  case "$1" in
    01) echo 5401 ;; 02) echo 5402 ;; 03) echo 5403 ;;
    04) echo 5404 ;; 05) echo 5405 ;; 06) echo 5406 ;;
  esac
}

redis_port() {
  case "$1" in
    01) echo 6301 ;; 02) echo 6302 ;; 03) echo 6303 ;;
    04) echo "" ;;  05) echo 6305 ;; 06) echo 6306 ;;
  esac
}

# ── 샘플 번호 해석 (1 → 01) ──────────────────────────────────────
resolve_sample() {
  local num
  num=$(printf '%02d' "${1#0}" 2>/dev/null) || error "잘못된 샘플 번호: $1"
  [[ -n "$(sample_dir "$num")" ]] || error "존재하지 않는 샘플: $num (01~06)"
  echo "$num"
}

compose_cmd() {
  local num="$1"; shift
  docker compose \
    -f "$SCRIPT_DIR/$(sample_dir "$num")/.devcontainer/docker-compose.yml" \
    --project-name "dc-${num}" "$@"
}

# ── code-server (공용 1개) ────────────────────────────────────────
cmd_ide() {
  if docker ps --format '{{.Names}}' | grep -q "^${CODE_SERVER_NAME}$"; then
    local host_ip
    host_ip=$(ipconfig getifaddr en0 2>/dev/null || echo "localhost")
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
  host_ip=$(ipconfig getifaddr en0 2>/dev/null || echo "localhost")
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
  local name pg redis
  name=$(sample_dir "$num")
  pg=$(pg_port "$num")
  redis=$(redis_port "$num")

  echo ""
  echo -e "${BOLD}${CYAN}━━ dc up · ${name} ━━${NC}"

  info "DB / Redis 시작 중..."
  compose_cmd "$num" up -d --remove-orphans
  success "PostgreSQL :${pg}  Redis :${redis:-없음}"

  if command -v devcontainer &>/dev/null; then
    info "앱 컨테이너(devcontainer) 시작 중..."
    devcontainer up --workspace-folder "$SCRIPT_DIR/${name}" 2>/dev/null \
      && success "devcontainer 준비 완료" \
      || warn "devcontainer CLI 실패 — DB/Redis는 정상 실행 중"
  else
    warn "devcontainer CLI 없음. start.sh 를 먼저 실행하면 자동 설치됩니다."
  fi

  echo ""
  echo -e "${BOLD}  접속 정보${NC}"
  echo -e "  PostgreSQL  →  localhost:${pg}  (dev / devpassword)"
  [[ -n "$redis" ]] && echo -e "  Redis       →  localhost:${redis}"
  echo -e "  IDE         →  ${CYAN}http://localhost:${CODE_SERVER_PORT}${NC}  (./dc.sh ide 로 시작)"
  echo ""
}

# ── down ────────────────────────────────────────────────────────
cmd_down() {
  [[ -n "${1:-}" ]] || error "샘플 번호를 입력하세요. 예: ./dc.sh down 1"
  local num
  num=$(resolve_sample "$1")

  echo ""
  echo -e "${BOLD}${CYAN}━━ dc down · $(sample_dir "$num") ━━${NC}"
  compose_cmd "$num" down
  success "$(sample_dir "$num") 종료 완료"
}

# ── restart ──────────────────────────────────────────────────────
cmd_restart() {
  [[ -n "${1:-}" ]] || error "샘플 번호를 입력하세요."
  local num
  num=$(resolve_sample "$1")
  cmd_down "$num"
  echo ""
  cmd_up "$num"
}

# ── status ───────────────────────────────────────────────────────
cmd_status() {
  local host_ip
  host_ip=$(ipconfig getifaddr en0 2>/dev/null || echo "localhost")

  echo ""
  if docker ps --format '{{.Names}}' | grep -q "^${CODE_SERVER_NAME}$"; then
    echo -e "  ${GREEN}● IDE (code-server)${NC}  http://localhost:${CODE_SERVER_PORT}  |  http://${host_ip}:${CODE_SERVER_PORT}"
  else
    echo -e "  ${RED}○ IDE (code-server)${NC}  중지됨  (./dc.sh ide 로 시작)"
  fi
  echo ""
  printf "${BOLD}  %-4s %-28s %-10s %-10s %-10s${NC}\n" "No." "샘플" "상태" "PG" "Redis"
  echo -e "  ──────────────────────────────────────────────────────"

  local num name pg redis running
  for num in 01 02 03 04 05 06; do
    name=$(sample_dir "$num")
    pg=":$(pg_port "$num")"
    redis=$(redis_port "$num")
    redis="${redis:+:${redis}}"
    redis="${redis:----}"

    if docker ps --format '{{.Names}}' | grep -q "dc-${num}"; then
      printf "  ${GREEN}%-4s${NC} %-28s ${GREEN}%-10s${NC} %-10s %s\n" \
        "$num" "$name" "● 실행중" "$pg" "$redis"
    else
      printf "  %-4s %-28s ${RED}%-10s${NC} %-10s %s\n" \
        "$num" "$name" "○ 중지" "$pg" "$redis"
    fi
  done
  echo ""
}

# ── logs ─────────────────────────────────────────────────────────
cmd_logs() {
  [[ -n "${1:-}" ]] || error "샘플 번호를 입력하세요."
  local num
  num=$(resolve_sample "$1")
  local service="${2:-}"
  info "$(sample_dir "$num") 로그 (Ctrl+C 중단)"
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
  [[ -n "${1:-}" ]] || error "샘플 번호를 입력하세요."
  local num
  num=$(resolve_sample "$1")

  if command -v devcontainer &>/dev/null; then
    devcontainer exec --workspace-folder "$SCRIPT_DIR/$(sample_dir "$num")" bash
  else
    docker exec -it "dc-${num}-app-1" bash 2>/dev/null \
      || error "실행 중인 앱 컨테이너가 없습니다. 먼저 ./dc.sh up $num"
  fi
}

# ── 인터랙티브 TUI 메뉴 (bash 3.2 호환) ─────────────────────────
# _tui_select: 전역 TUI_ITEMS 배열을 읽어 선택된 인덱스를 TUI_RESULT에 저장
TUI_ITEMS=()
TUI_RESULT=0

_tui_render() {
  local i=0
  while [[ $i -lt ${#TUI_ITEMS[@]} ]]; do
    if [[ $i -eq $TUI_RESULT ]]; then
      echo -e "  ${CYAN}▶${NC} ${BOLD}${TUI_ITEMS[$i]}${NC}"
    else
      echo -e "    ${TUI_ITEMS[$i]}"
    fi
    i=$((i + 1))
  done
}

_tui_select() {
  local total=${#TUI_ITEMS[@]}
  TUI_RESULT=0

  tput civis 2>/dev/null || true
  trap 'tput cnorm 2>/dev/null; echo ""; exit 130' INT TERM

  _tui_render

  while true; do
    local key rest
    IFS= read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
      read -rsn2 -t 0.1 rest || true
      case "$rest" in
        '[A') [[ $TUI_RESULT -gt 0 ]] && TUI_RESULT=$((TUI_RESULT - 1)) ;;
        '[B') [[ $TUI_RESULT -lt $((total - 1)) ]] && TUI_RESULT=$((TUI_RESULT + 1)) ;;
      esac
    elif [[ $key == '' ]]; then
      break
    elif [[ $key == 'q' ]]; then
      tput cnorm 2>/dev/null; echo ""; exit 0
    fi

    local i=0
    while [[ $i -lt $total ]]; do
      tput cuu1 2>/dev/null; tput el 2>/dev/null
      i=$((i + 1))
    done
    _tui_render
  done

  tput cnorm 2>/dev/null
}

cmd_menu() {
  while true; do
    clear
    echo ""
    echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}  ║     Devcontainer Manager  dc.sh      ║${NC}"
    echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════╝${NC}"
    echo ""

    if docker ps --format '{{.Names}}' | grep -q "^${CODE_SERVER_NAME}$" 2>/dev/null; then
      echo -e "  ${GREEN}● IDE${NC}  http://localhost:${CODE_SERVER_PORT}"
    else
      echo -e "  ${RED}○ IDE${NC}  중지됨"
    fi
    echo ""

    TUI_ITEMS=(
      "IDE 시작 / 열기  (code-server :8080)"
      "전체 상태 보기"
      "샘플 시작  (up)"
      "샘플 종료  (down)"
      "샘플 재시작"
      "로그 보기"
      "쉘 접속"
      "실행 컨테이너 목록"
      "IDE 종료"
      "종료"
    )

    _tui_select
    local sel=$TUI_RESULT
    echo ""

    case $sel in
      0) cmd_ide; echo ""; read -rp "  [Enter 계속]" || true ;;
      1) cmd_status; read -rp "  [Enter 계속]" || true ;;
      2) _menu_pick_sample "up" ;;
      3) _menu_pick_sample "down" ;;
      4) _menu_pick_sample "restart" ;;
      5) _menu_pick_sample "logs" ;;
      6) _menu_pick_sample "shell" ;;
      7) cmd_ps; read -rp "  [Enter 계속]" || true ;;
      8) cmd_ide_stop; echo ""; read -rp "  [Enter 계속]" || true ;;
      9) echo ""; exit 0 ;;
    esac
  done
}

_menu_pick_sample() {
  local action="$1"

  echo -e "  ${BOLD}샘플 선택${NC}  (↑↓ 이동, Enter 확인, q 취소)"
  echo ""

  TUI_ITEMS=(
    "01  Admin Dashboard      PG:5401  Redis:6301"
    "02  B2C Web Service      PG:5402  Redis:6302"
    "03  AI/ML API            PG:5403  Redis:6303"
    "04  Mobile App           PG:5404"
    "05  Node Microservice    PG:5405  Redis:6305"
    "06  Data Pipeline        PG:5406  Redis:6306"
    "<-- 돌아가기"
  )

  _tui_select
  local sel=$TUI_RESULT
  echo ""

  [[ $sel -eq 6 ]] && return

  local num
  num=$(printf '%02d' $((sel + 1)))

  case "$action" in
    up)      cmd_up "$num" ;;
    down)    cmd_down "$num" ;;
    restart) cmd_restart "$num" ;;
    logs)    cmd_logs "$num" ;;
    shell)   cmd_shell "$num" ;;
  esac

  echo ""
  read -rp "  [Enter 계속]" || true
}

# ── help ────────────────────────────────────────────────────────
cmd_help() {
  echo ""
  echo -e "${BOLD}${CYAN}  dc.sh — Devcontainer Manager${NC}"
  echo ""
  echo -e "  ${BOLD}사용법:${NC}  ./dc.sh [command] [번호]"
  echo -e "  인수 없이 실행하면 인터랙티브 메뉴가 열립니다."
  echo ""
  echo -e "  ${BOLD}Commands:${NC}"
  echo -e "    ${GREEN}ide${NC}              브라우저 IDE (code-server :8080) 시작"
  echo -e "    ${GREEN}ide stop${NC}         code-server 종료"
  echo -e "    ${GREEN}up${NC}    <번호>     샘플 DB + 앱 컨테이너 시작"
  echo -e "    ${GREEN}down${NC}  <번호>     종료"
  echo -e "    ${GREEN}restart${NC} <번호>   재시작"
  echo -e "    ${GREEN}status${NC}           전체 현황"
  echo -e "    ${GREEN}logs${NC}  <번호>     로그 스트리밍"
  echo -e "    ${GREEN}ps${NC}               실행 컨테이너 목록"
  echo -e "    ${GREEN}shell${NC} <번호>     컨테이너 쉘 접속"
  echo ""
  echo -e "  ${BOLD}포트 배분${NC}"
  echo -e "    01 admin-dashboard    PG:5401  Redis:6301"
  echo -e "    02 nextjs-web         PG:5402  Redis:6302"
  echo -e "    03 ai-api             PG:5403  Redis:6303"
  echo -e "    04 mobile-app         PG:5404"
  echo -e "    05 node-microservice  PG:5405  Redis:6305"
  echo -e "    06 data-pipeline      PG:5406  Redis:6306"
  echo -e "    IDE code-server       :8080"
  echo ""
}

# ── 메인 ────────────────────────────────────────────────────────
main() {
  if [[ $# -eq 0 ]]; then
    cmd_menu
    return
  fi

  local cmd="$1"; shift

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
