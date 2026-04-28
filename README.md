# Devcontainer Samples

회사 업무에서 자주 사용하는 기술 스택별 Dev Container 샘플 모음입니다.
모든 샘플에는 **Claude Code CLI**가 사전 설치되어 AI 코딩 환경을 바로 사용할 수 있습니다.

## 샘플 목록

| 폴더 | 스택 | 포트 |
|------|------|------|
| [01-node-typescript](./01-node-typescript) | Node.js 20 + TypeScript | 3000 |
| [02-python-fastapi](./02-python-fastapi) | Python 3.12 + FastAPI | 8000 |
| [03-vite-react](./03-vite-react) | Vite + React + TypeScript | 5173 |
| [04-html-css-dashboard](./04-html-css-dashboard) | HTML/CSS + Live Server | 5500 |
| [05-python-datascience](./05-python-datascience) | Python + Jupyter + pandas | 8888 |
| [06-fullstack](./06-fullstack) | Node.js + Python (풀스택) | 3000, 8000 |

## 사용 방법

1. 원하는 샘플 폴더를 VS Code로 열기
2. `Cmd+Shift+P` → `Dev Containers: Reopen in Container`
3. 컨테이너 빌드 완료 후 터미널에서 `claude` 명령어 사용 가능

## 요구사항

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [VS Code](https://code.visualstudio.com/) + [Dev Containers 확장](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

## Claude Code 인증

컨테이너 진입 후 최초 1회 실행:
```bash
claude
```
브라우저가 열리면 Anthropic 계정으로 로그인하거나 API 키를 입력하세요.
