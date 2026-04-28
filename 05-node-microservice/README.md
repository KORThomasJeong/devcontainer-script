# Node.js 마이크로서비스 — Fastify + PostgreSQL + Redis

고성능 REST API 서버용 환경. Fastify + TypeScript + Drizzle ORM 조합.

## 서비스 구성

| 서비스 | 이미지 | 포트 | 용도 |
|---|---|---|---|
| app | node:20 devcontainer | — | 개발 컨테이너 |
| db | postgres:16-alpine | 5432 | 메인 DB |
| redis | redis:7-alpine | 6379 | 캐시 / Rate limit / 큐 |

## 포트

- `3000` — Fastify API 서버
- `5432` — PostgreSQL
- `6379` — Redis

## 시작하기

```bash
npm init -y
npm install fastify @fastify/cors @fastify/jwt drizzle-orm postgres ioredis zod
npm install -D typescript @types/node drizzle-kit tsx

# 서버 실행
npx tsx watch src/server.ts
```

## 추천 스택

- `fastify` — Express 대비 3x 빠른 HTTP 프레임워크
- `drizzle-orm` — 타입세이프 SQL ORM (Prisma 대안)
- `ioredis` — Redis 클라이언트
- `@fastify/jwt` — JWT 인증
- `zod` — 입력 검증
- `bullmq` — Redis 기반 작업 큐
