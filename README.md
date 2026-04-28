# Devcontainer Samples

프로젝트 유형별 Dev Container 샘플 모음. 각 샘플은 **앱 서버 + DB + 캐시**가 docker-compose로 구성되어 있으며 **Claude Code CLI**가 사전 설치됩니다.

## 샘플 목록

| 폴더 | 용도 | 스택 |
|------|------|------|
| [01-admin-dashboard](./01-admin-dashboard) | 어드민 / 대시보드 | Vite+React + FastAPI + PostgreSQL + Redis |
| [02-nextjs-web](./02-nextjs-web) | B2C 웹서비스 | Next.js + Prisma + PostgreSQL + Redis |
| [03-ai-api](./03-ai-api) | AI/ML API 서버 | FastAPI + pgvector + Redis + Anthropic SDK |
| [04-mobile-app](./04-mobile-app) | 모바일 앱 | Expo (React Native) + FastAPI + PostgreSQL |
| [05-node-microservice](./05-node-microservice) | REST 마이크로서비스 | Fastify + PostgreSQL + Redis |
| [06-data-pipeline](./06-data-pipeline) | 데이터 파이프라인 | Python + PostgreSQL + Redis + Jupyter |

## 사용 방법

1. `./start.sh` 실행 → 샘플 선택
2. VS Code: `Cmd+Shift+P` → `Dev Containers: Reopen in Container`
3. 컨테이너 터미널에서 `claude` 실행

## 요구사항

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [VS Code](https://code.visualstudio.com/) + [Dev Containers 확장](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
