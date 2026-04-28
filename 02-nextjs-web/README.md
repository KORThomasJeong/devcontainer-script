# B2C 웹서비스 — Next.js + Prisma + PostgreSQL + Redis

SEO가 필요한 고객향 웹서비스용 환경. App Router 기반 Next.js 14에 Prisma ORM, NextAuth 인증 포함.

## 서비스 구성

| 서비스 | 이미지 | 포트 | 용도 |
|---|---|---|---|
| app | node:20 devcontainer | — | 개발 컨테이너 |
| db | postgres:16-alpine | 5432 | 메인 DB |
| redis | redis:7-alpine | 6379 | 세션 / 캐시 |

## 포트

- `3000` — Next.js (SSR + API Routes)
- `5432` — PostgreSQL
- `6379` — Redis

## 시작하기

```bash
# Next.js 프로젝트 생성
npx create-next-app@latest . --typescript --tailwind --app --src-dir

# Prisma 초기화
npm install prisma @prisma/client
npx prisma init

# DB 마이그레이션 & 실행
npx prisma migrate dev
npm run dev
```

## 추천 라이브러리

- `next-auth` — 소셜 로그인 / 세션
- `@prisma/client` — 타입세이프 ORM
- `ioredis` — Redis 클라이언트
- `zod` — 스키마 검증
- `shadcn/ui` + Tailwind — UI 컴포넌트
