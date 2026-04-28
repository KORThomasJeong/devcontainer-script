# Python + FastAPI Devcontainer

Python 3.12 기반의 FastAPI 백엔드 개발 환경입니다.

## 포함 도구

- Python 3.12
- FastAPI + Uvicorn
- Pydantic v2
- Black + Ruff (코드 포맷/린트)
- Claude Code CLI

## 시작하기

```bash
# main.py 생성 후 실행
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

```python
# main.py 예시
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello, FastAPI!"}
```

## API 문서

서버 실행 후 브라우저에서 확인:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 포트

- `8000` — FastAPI 서버
