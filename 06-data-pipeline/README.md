# 데이터 파이프라인 — Python + PostgreSQL + Redis + Jupyter

ETL 파이프라인, 데이터 분석, 리포팅 개발 환경. DB는 raw/staging/mart 스키마로 분리됩니다.

## 서비스 구성

| 서비스 | 이미지 | 포트 | 용도 |
|---|---|---|---|
| app | python:3.12 devcontainer | — | 개발 컨테이너 |
| db | postgres:16-alpine | 5432 | raw / staging / mart 스키마 |
| redis | redis:7-alpine | 6379 | 작업 큐 / 캐시 |

## 포트

- `8888` — Jupyter Lab
- `8080` — 대시보드 (Streamlit/Superset)
- `5432` — PostgreSQL
- `6379` — Redis

## DB 스키마 구조

```
datadb
├── raw      # 원시 수집 데이터
├── staging  # 변환 중간 테이블
└── mart     # 분석용 최종 테이블 (BI 연결)
```

## 시작하기

```bash
# Jupyter Lab
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.token=''

# dbt 프로젝트 초기화
dbt init project_name

# Streamlit 대시보드
pip install streamlit
streamlit run dashboard.py --server.port=8080
```

## 포함 라이브러리

- `pandas`, `numpy` — 데이터 처리
- `sqlalchemy`, `psycopg2` — DB 연결
- `dbt-postgres` — SQL 변환 파이프라인
- `great-expectations` — 데이터 품질 검증
- `redis` — 작업 큐 / 결과 캐싱
- `openpyxl` — Excel 파일 처리
