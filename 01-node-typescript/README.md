# Node.js + TypeScript Devcontainer

Node.js 20 기반의 TypeScript 개발 환경입니다.

## 포함 도구

- Node.js 20 LTS
- TypeScript (최신)
- ESLint + Prettier
- Claude Code CLI

## 시작하기

```bash
# 새 프로젝트 초기화
npm init -y
npm install typescript ts-node @types/node --save-dev
npx tsc --init

# 또는 Express API
npm install express
npm install @types/express --save-dev
```

## 포트

- `3000` — 앱 기본 포트
