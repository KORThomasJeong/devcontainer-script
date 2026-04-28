# Python Data Science Devcontainer

Python 3.12 기반의 데이터 분석 및 시각화 개발 환경입니다.

## 포함 도구

- Python 3.12
- Jupyter Lab
- pandas, numpy
- matplotlib, seaborn, plotly
- scikit-learn
- openpyxl (Excel 파일 처리)
- Claude Code CLI

## 시작하기

```bash
# Jupyter Lab 실행
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.token=''
```

또는 VS Code에서 `.ipynb` 파일을 열어 직접 실행할 수 있습니다.

```python
# 기본 분석 예시
import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv('data.csv')
df.describe()
```

## 포트

- `8888` — Jupyter Lab
