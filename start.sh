#!/usr/bin/env bash
set -euo pipefail

# ── 색상 출력 ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERR]${NC}  $*"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 사용 가능한 포트 찾기 ──────────────────────────────────────
find_free_port() {
  local start=$1
  local port=$start
  while lsof -iTCP:"$port" -sTCP:LISTEN -t &>/dev/null 2>&1; do
    ((port++))
  done
  echo "$port"
}

# ── devcontainer.json 포트 패치 ────────────────────────────────
patch_ports() {
  local json_file="$1"
  shift
  local ports=("$@")

  local tmp
  tmp=$(mktemp)
  local patch='.'
  local i=0
  for port in "${ports[@]}"; do
    local free
    free=$(find_free_port "$port")
    if [[ "$free" != "$port" ]]; then
      warn "포트 $port 사용 중 → $free 로 변경"
      patch+=" | .forwardPorts[$i] = $free"
    fi
    ((i++)) || true
  done
  # python -c로 JSON 수정 (jq 없어도 동작)
  python3 - "$json_file" "$patch" <<'PYEOF' > "$tmp"
import json, sys, re

path = sys.argv[1]
patch_expr = sys.argv[2]

with open(path) as f:
    data = json.load(f)

# parse patch: .forwardPorts[N] = V
for m in re.finditer(r'\.forwardPorts\[(\d+)\]\s*=\s*(\d+)', patch_expr):
    idx, val = int(m.group(1)), int(m.group(2))
    if idx < len(data.get('forwardPorts', [])):
        data['forwardPorts'][idx] = val

print(json.dumps(data, indent=2))
PYEOF
  cp "$tmp" "$json_file"
  rm "$tmp"
}

# ── 사전 요구사항 체크 & 설치 ──────────────────────────────────
check_prerequisites() {
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  사전 요구사항 확인${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  # Docker
  if ! command -v docker &>/dev/null; then
    error "Docker가 설치되지 않았습니다. https://www.docker.com/products/docker-desktop 에서 설치하세요."
  fi
  if ! docker info &>/dev/null 2>&1; then
    error "Docker가 실행 중이지 않습니다. Docker Desktop을 시작하세요."
  fi
  success "Docker $(docker --version | awk '{print $3}' | tr -d ',')"

  # Node.js & npm
  if ! command -v node &>/dev/null; then
    error "Node.js가 설치되지 않았습니다. https://nodejs.org 에서 설치하세요."
  fi
  success "Node.js $(node --version)"

  # devcontainer CLI
  if ! command -v devcontainer &>/dev/null; then
    info "devcontainer CLI 설치 중 (~/.npm-global 사용)..."
    # sudo 없이 사용자 디렉토리에 설치
    npm config set prefix "$HOME/.npm-global"
    export PATH="$HOME/.npm-global/bin:$PATH"
    npm install -g @devcontainers/cli
    # 셸 설정 파일에 PATH 영구 추가 (중복 방지)
    local shell_rc="$HOME/.zshrc"
    [[ "$SHELL" == */bash ]] && shell_rc="$HOME/.bashrc"
    if ! grep -q '.npm-global/bin' "$shell_rc" 2>/dev/null; then
      echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$shell_rc"
      info "PATH 설정이 $shell_rc 에 추가되었습니다."
    fi
    success "devcontainer CLI 설치 완료"
  else
    success "devcontainer CLI $(devcontainer --version 2>/dev/null || echo '설치됨')"
  fi

  # python3 (포트 패치용)
  if ! command -v python3 &>/dev/null; then
    warn "python3가 없습니다. 포트 자동 패치 기능을 사용할 수 없습니다."
  fi
}

# ── 샘플 선택 메뉴 ─────────────────────────────────────────────
select_sample() {
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  Devcontainer 샘플 선택${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "  ${CYAN}1)${NC} Node.js + TypeScript       (포트: 3000)"
  echo -e "  ${CYAN}2)${NC} Python + FastAPI            (포트: 8000)"
  echo -e "  ${CYAN}3)${NC} Vite + React                (포트: 5173)"
  echo -e "  ${CYAN}4)${NC} HTML/CSS Dashboard          (포트: 5500)"
  echo -e "  ${CYAN}5)${NC} Python Data Science         (포트: 8888)"
  echo -e "  ${CYAN}6)${NC} Full-Stack (Node + Python)  (포트: 5173, 8000)"
  echo ""
  read -rp "$(echo -e ${BOLD}"번호를 선택하세요 [1-6]: "${NC})" choice

  case "$choice" in
    1) SAMPLE_DIR="01-node-typescript";    PORTS=(3000) ;;
    2) SAMPLE_DIR="02-python-fastapi";     PORTS=(8000) ;;
    3) SAMPLE_DIR="03-vite-react";         PORTS=(5173) ;;
    4) SAMPLE_DIR="04-html-css-dashboard"; PORTS=(5500) ;;
    5) SAMPLE_DIR="05-python-datascience"; PORTS=(8888) ;;
    6) SAMPLE_DIR="06-fullstack";          PORTS=(5173 8000) ;;
    *) error "잘못된 선택입니다." ;;
  esac

  WORKSPACE="$SCRIPT_DIR/$SAMPLE_DIR"
  JSON_FILE="$WORKSPACE/.devcontainer/devcontainer.json"
}

# ── 포트 체크 & 표시 ───────────────────────────────────────────
check_ports() {
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  포트 가용성 확인${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  local changed=false
  for port in "${PORTS[@]}"; do
    local free
    free=$(find_free_port "$port")
    if [[ "$free" == "$port" ]]; then
      success "포트 $port — 사용 가능"
    else
      warn "포트 $port — 사용 중 (→ $free 로 자동 변경)"
      changed=true
    fi
  done

  if [[ "$changed" == "true" ]] && command -v python3 &>/dev/null; then
    patch_ports "$JSON_FILE" "${PORTS[@]}"
    success "devcontainer.json 포트 업데이트 완료"
  fi
}

# ── 원격 접속 정보 출력 ────────────────────────────────────────
show_access_info() {
  local host_ip
  host_ip=$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")

  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  접속 정보${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  for port in "${PORTS[@]}"; do
    local free
    free=$(find_free_port "$port")
    echo -e "  ${GREEN}로컬${NC}:  http://localhost:$free"
    echo -e "  ${GREEN}원격${NC}:  http://$host_ip:$free"
  done
  echo ""
  echo -e "  ${CYAN}VS Code 원격 연결${NC}: Cmd+Shift+P → 'Dev Containers: Attach to Running Container'"
  echo ""
}

# ── 컨테이너 실행 ─────────────────────────────────────────────
run_container() {
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  컨테이너 시작: $SAMPLE_DIR${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  info "devcontainer up 실행 중... (첫 실행 시 이미지 다운로드로 수 분 소요)"
  devcontainer up --workspace-folder "$WORKSPACE"

  success "컨테이너 시작 완료!"
  show_access_info
}

# ── 메인 ──────────────────────────────────────────────────────
main() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║     Devcontainer Launcher + Claude Code  ║${NC}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════╝${NC}"

  check_prerequisites
  select_sample
  check_ports
  run_container
}

main "$@"
