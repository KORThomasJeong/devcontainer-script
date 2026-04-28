# Full-Stack Devcontainer (Node.js + Python)

Vite/React 프론트엔드와 FastAPI 백엔드를 동시에 개발하는 풀스택 환경입니다.

## 포함 도구

- Node.js 20 LTS
- Python 3.12
- FastAPI + Uvicorn
- Vite + React 지원
- ESLint + Prettier + Black + Ruff
- Claude Code CLI

## 시작하기

**백엔드 (FastAPI)**
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**프론트엔드 (Vite + React)**
```bash
cd frontend
npm install
npm run dev -- --host 0.0.0.0
```

## 권장 프로젝트 구조

```
.
├── backend/
│   ├── main.py
│   └── requirements.txt
└── frontend/
    ├── src/
    ├── package.json
    └── vite.config.ts
```

## 포트

- `5173` — Vite 프론트엔드
- `8000` — FastAPI 백엔드 (Swagger: http://localhost:8000/docs)
