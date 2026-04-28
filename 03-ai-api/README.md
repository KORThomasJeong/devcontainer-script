# AI/ML API 서버 — FastAPI + pgvector + Redis + Anthropic

LLM 연동 AI 기능 API 서버 개발 환경. pgvector로 벡터 검색, Redis로 응답 캐싱.

## 서비스 구성

| 서비스 | 이미지 | 포트 | 용도 |
|---|---|---|---|
| app | python:3.12 devcontainer | — | 개발 컨테이너 |
| db | pgvector/pgvector:pg16 | 5432 | PostgreSQL + 벡터 확장 |
| redis | redis:7-alpine | 6379 | 응답 캐시 / Rate limit |

## 포트

- `8000` — FastAPI (`/docs` Swagger)
- `8888` — Jupyter Lab (프로토타이핑)
- `5432` — PostgreSQL (pgvector 포함)
- `6379` — Redis

## API Key 설정

루트에 `.env` 파일 생성:
```bash
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...  # 선택
```

## 시작하기

```bash
# API 서버
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Jupyter Lab (프로토타이핑)
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.token=''

# pgvector 확장 활성화
psql $DATABASE_URL -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

## 포함 라이브러리

- `anthropic` — Claude API 클라이언트
- `langchain` — LLM 오케스트레이션
- `sentence-transformers` — 임베딩 생성
- `pgvector` — 벡터 유사도 검색
- `redis` — 캐싱 / Rate limiting
