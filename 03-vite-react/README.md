# Vite + React Devcontainer

Node.js 20 기반의 Vite + React TypeScript 프론트엔드 개발 환경입니다.

## 포함 도구

- Node.js 20 LTS
- Vite (최신)
- React 18 + TypeScript
- ESLint + Prettier
- Tailwind CSS 지원
- Claude Code CLI

## 시작하기

```bash
# React + TypeScript 프로젝트 생성
npm create vite@latest my-app -- --template react-ts
cd my-app
npm install
npm run dev -- --host 0.0.0.0
```

컨테이너 열리면 브라우저가 자동으로 http://localhost:5173 을 엽니다.

## 포트

- `5173` — Vite 개발 서버 (HMR 포함)
