# Capybara QR Order — 주문·매장 운영 SaaS 고도화 스타터 킷

**계획서 v0.2 · 2026-10-14 · Status: 제안(팀 합의 전)**

## 이번 판의 핵심 변경
v0.1은 프론트엔드 저장소만 검토했으나 v0.2는 **Flask 백엔드 저장소의 실제 코드까지 정적 검토**했다. 권고 기술 구성은 **Vue 3 + Flask 3 + SQLAlchemy + MySQL 계열 DB**를 유지하며 필요한 부분을 점진적으로 개선하는 A안이다. Spring Boot로 전면 재구축한다는 전제는 제거했고, 대안으로만 남겼다.

- 프론트: https://github.com/Capybara-Clinic/mnu_pub_order_system (`main`, `front-end/`)
- 백엔드: https://github.com/Capybara-Clinic/capybara-qr-order (`main`, `app/routes/`, `app/models/`)
- 검토일: **2026-10-14**. 코드를 읽은 **정적 분석**이므로 실행·동시성·배포 결과를 확인한 것은 아니다.
- 실제 데이터, 배포 자격, PG 계약 및 운영 매장 확보 여부: **미확인**.
- 본 ZIP은 계획·템플릿 문서이며 **두 GitHub 저장소에 반영되지 않았다**.

## 바로 볼 문서

| 파일 | 내용 |
|---|---|
| `PROJECT_PLAN_v0.2.md` | 팀 모집 전에 공유할 요약 계획서와 결정 포인트 |
| `01_PROJECT_CHARTER.md` | 제품 방향, 사용자, MVP, KPI, 비범위 |
| `02_REPO_AUDIT.md` | **두 저장소 코드 진단**, 구체적인 P0 기술 리스크와 재현 가설 |
| `03_PRODUCT_BACKLOG.md` | 기능 + 기술부채 백로그, 수용 기준, 우선순위 |
| `04_ARCHITECTURE.md` | **Flask 기반** 목표 구조, 트랜잭션 경계, API 및 데이터 흐름 |
| `05_PAYMENT_ERP.md` | Mock PG→PG sandbox→대사→ERP CSV/API 단계 |
| `06_TEAM_ROADMAP.md` | **안정화 우선 16주 일정**, 역할, 스프린트, 출시 게이트 |
| `07_DOCS_AUTOMATION.md` | **Python/Vue** CI, 테스트, 문서화·AI 활용 원칙 |
| `08_RECRUITMENT.md` | 실제 기존 코드가 있는 팀 모집 공고/킥오프 |
| `09_AS_IS_API_MATRIX.md` | **현행 BE–FE 엔드포인트/데이터 계약** 및 드리프트 |
| `10_DOMAIN_INVARIANTS_TESTS.md` | **도메인 불변식, 회귀·동시성·오류주입 테스트** |
| `11_DB_MIGRATION_PLAN.md` | **기존 7개 모델**에서 단계별 DB 확장·마이그레이션 |
| `12_SECURITY_OPERATIONS.md` | 인증·권한·개인정보·실서비스 준비·장애 대응 |
| `13_CHANGELOG_v0.2.md` | v0.1→v0.2 변경 이력과 결정 목록 |
| `.github/` | PR/Feature/Bug 템플릿, CODEOWNERS **예시** |
| `docs/adr/` | Flask 유지, 재고 정책 등 설계 결정 초안 |
| `docs/runbooks/` | 결제 대사·재고 불일치 대응 초안 |

## 우선 실행할 5단계
1. 백엔드 저장소에 별도 `LICENSE` 파일이 없으므로, 기여자 권리·재배포/라이선스 관계부터 확인한다(공개 저장소 ≠ 자유 라이선스).
2. Docker Compose로 **두 저장소 + MySQL** 로컬 구동을 재현하고 스키마·시드데이터·핵심 API 기록을 남긴다. 현재 이를 재현한 사실은 없다.
3. `order.py` 주문 시 재고 미차감 ↔ `cashier.py` 취소 시 재고 증가를 **테스트로 재현**하고 정책·불변식을 결정한다.
4. 캐셔/재고/주문 조회 API에 인증·매장별 권한 검사를 설계·적용하고, 결제·상태 변화를 검증한다.
5. 한 매장의 `QR→메뉴→주문→캐셔/주방→서빙→마감` 흐름을 통합·E2E 검증한다. 검증 후에만 멀티매장·PG sandbox·ERP로 확장한다.

## 주의
- `KNOWN`: 코드에 실제로 표현된 구현 사실. `RISK`: 정적 분석에서 합리적으로 예상하는 실패. `TO_VERIFY`: 구동·테스트로 확인할 사항. 이 셋을 구분한다.
- 실제 돈을 수납하거나 타인의 개인정보로 파일럿을 진행하기 전 관련 계약, 안전조치, 법적 요구사항을 따로 확인한다.
- 보안상 문제가 있는 현재 서버를 인터넷에 그대로 배포하지 않는다.
