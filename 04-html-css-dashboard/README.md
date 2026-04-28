# HTML/CSS Dashboard Devcontainer

순수 HTML/CSS로 대시보드를 빠르게 프로토타이핑하는 개발 환경입니다.
VS Code Live Server로 파일 저장 즉시 브라우저에 반영됩니다.

## 포함 도구

- Node.js 20 (Claude Code 실행용)
- VS Code Live Server
- HTML/CSS IntelliSense
- Auto Rename/Close Tag
- Color Highlight
- Claude Code CLI

## 시작하기

1. `index.html` 파일 생성
2. VS Code에서 `Go Live` 버튼 클릭 (우측 하단)
3. 또는 `Cmd+Shift+P` → `Live Server: Open with Live Server`

```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Dashboard</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <h1>Dashboard</h1>
</body>
</html>
```

## 포트

- `5500` — Live Server (핫 리로드 포함)
