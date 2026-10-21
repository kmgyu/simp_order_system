# Capybara QR Order — 통합 주문·매장 운영 SaaS

교내 행사 학생 포차용 QR 주문 시스템(Vue 3 FE + Flask 3 BE)을 소상공인용 매장 운영 SaaS로 고도화하는 프로젝트입니다.

---

## 1. 프로젝트 구조

```text
.
├── capybara_qr_order/      # [Backend] Flask 3.1 + SQLAlchemy + PyMySQL REST API
├── mnu_pub_order_system/   # [Frontend] Vue 3 + Pinia + Tailwind CSS SPA
├── scripts/
│   ├── mysql/
│   │   ├── 01_init.sql     # DB DDL 초기화 스크립트 (7개 모델 기반)
│   │   └── 02_seed.sql     # 로컬 개발 및 테스트 시나리오용 시드 데이터
│   ├── dev-up.ps1          # 로컬 Docker 환경 원클릭 실행 스크립트
│   └── dev-down.ps1        # 로컬 Docker 환경 정리 스크립트
├── docs/
│   ├── planning/           # 고도화 프로젝트 기획서 및 명세서 (v0.2)
│   └── antigravity/        # Antigravity 에이전트 문서 및 체크리스트
├── docker-compose.yml      # 통합 로컬 개발 오케스트레이션
├── .env.example            # 루트 환경변수 템플릿
└── AGENTS.md               # 에이전트 운영 계약 및 행동 규칙
```

---

## 2. 로컬 빠른 시작 (Quick Start)

### 사전 요구사항
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) 설치 및 실행

### 실행 방법
```powershell
# 1. 환경변수 파일 복사 (필요 시 수정)
cp .env.example .env

# 2. Docker Compose 빌드 및 실행
docker compose up -d --build
```
*PowerShell 스크립트 이용 시:*
```powershell
.\scripts\dev-up.ps1
```

---

## 3. 서비스 접속 안내

| 서비스 | 주소 | 비고 |
|---|---|---|
| **Frontend UI** | [http://localhost:8080](http://localhost:8080) | 모바일 QR 주문, 캐셔/주방/서빙 화면 |
| **Backend API** | [http://localhost:3000](http://localhost:3000) | Flask REST API 엔드포인트 |
| **MySQL DB** | `localhost:3306` | DB: `capybara_order` / 계정: `order_user` (암호: `order_password`) |

---

## 4. 로컬 테스트 데이터 (Seed)

MySQL 컨테이너 최초 실행 시 `scripts/mysql/`의 스크립트가 자동 적용됩니다.
- **매장 테이블**: 1 ~ 12번 테이블 및 QR 코드 등록
- **메뉴**:
  - `어묵탕` (menu_id=4): 재고 10개 (A01 재고 버그 회귀 테스트용)
  - `치즈계란말이` (menu_id=5): 재고 1개 (동시 주문 경쟁 조건 테스트용)
  - `참치마요주먹밥` (menu_id=6): 품절 메뉴 (재고 0, is_available=False)
  - `참이슬/맥주/음료` (menu_id=7~9): 무제한 재고 (stock_quantity=NULL)

---

## 5. 컨테이너 중지 및 초기화

```powershell
# 컨테이너 중지
docker compose down

# DB 데이터까지 완전히 초기화할 경우
docker compose down -v
```
