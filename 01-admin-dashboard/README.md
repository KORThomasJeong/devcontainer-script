# Admin Dashboard — Vite + React + FastAPI + PostgreSQL + Redis

사내 어드민 패널, 데이터 대시보드 개발용 풀스택 환경입니다.

## 서비스 구성

| 서비스 | 이미지 | 포트 | 용도 |
|---|---|---|---|
| app | python:3.12 devcontainer | — | 개발 컨테이너 |
| db | postgres:16-alpine | 5432 | 메인 DB |
| redis | redis:7-alpine | 6379 | 캐시 / 세션 |

## 포트

- `5173` — Vite 프론트엔드 (HMR)
- `8000` — FastAPI 백엔드 (`/docs` Swagger 자동 생성)
- `5432` — PostgreSQL
- `6379` — Redis

## 환경변수

`.devcontainer/docker-compose.yml`에 기본값 설정됨:
```
DATABASE_URL=postgresql+asyncpg://dev:devpassword@db:5432/admindb
REDIS_URL=redis://redis:6379
```

## 시작하기

```bash
# 백엔드
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# 프론트엔드 (새 터미널)
npm create vite@latest frontend -- --template react-ts
cd frontend && npm install && npm run dev -- --host 0.0.0.0

# DB 마이그레이션
alembic upgrade head
```

## 추천 라이브러리

- 프론트엔드: Tanstack Query, Recharts, shadcn/ui, Tailwind CSS
- 백엔드: SQLAlchemy 2.0 (async), Alembic, redis-py
