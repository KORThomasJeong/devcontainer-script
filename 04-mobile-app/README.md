# 모바일 앱 — Expo (React Native) + FastAPI + PostgreSQL

iOS/Android 앱 + API 서버를 동시에 개발하는 환경입니다.
Expo Go 앱으로 실제 기기에서 즉시 테스트할 수 있습니다.

## 서비스 구성

| 서비스 | 이미지 | 포트 | 용도 |
|---|---|---|---|
| app | python:3.12 devcontainer | — | 개발 컨테이너 (host network) |
| db | postgres:16-alpine | 5432 | 메인 DB |

## 포트

- `8081` — Expo Dev Client
- `19000` — Expo Go (QR 코드 연결)
- `19001` — Metro Bundler
- `8000` — FastAPI 백엔드

## 시작하기

```bash
# Expo 프로젝트 생성
npx create-expo-app mobile --template blank-typescript
cd mobile

# Expo 개발 서버 (같은 WiFi에서 QR 코드로 실기기 연결)
npx expo start --tunnel

# FastAPI 백엔드 (새 터미널)
uvicorn api.main:app --reload --host 0.0.0.0 --port 8000
```

## 실기기 연결 방법

1. 스마트폰에 **Expo Go** 앱 설치
2. `npx expo start --tunnel` 실행
3. 앱에서 QR 코드 스캔

> **Note**: `network_mode: host`로 설정되어 있어 호스트와 같은 네트워크를 공유합니다.
> 실기기 QR 스캔이 필요할 경우 `--tunnel` 옵션을 사용하세요.

## 추천 라이브러리

- `expo-router` — 파일 기반 내비게이션
- `@tanstack/react-query` — 서버 상태 관리
- `zustand` — 클라이언트 상태 관리
- `nativewind` — Tailwind for React Native
