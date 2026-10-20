# 문서 작성·CI/CD·AI 사용 규칙 — Flask/Vue 기준 v0.2

## 1. 정본 문서와 경로
- 요구사항: `docs/product/PRD.md`, user story/acceptance criteria.
- 현행 API 계약: `09_AS_IS_API_MATRIX.md`; 이후 정본은 `docs/api/openapi.yaml`(생성/검증 대상).
- 데이터 모델: `docs/db/schema.md` + Alembic/Flask-Migrate migrations (**실제 스키마 변경 정본**).
- 아키텍처 의사결정: `docs/adr/NNNN-*.md` (시점·대안·트레이드오프·검증/재검토 조건).
- 운영 장애: `docs/runbooks/*`, `incidents/YYYY-MM-DD-title.md`.
- PR 결과: 템플릿 내 테스트 증거, 배포/롤백 영향, 관련 이슈.
- 문서들은 처음부터 두 코드 저장소에 모두 복사하지 않는다. **정본 저장소/링크를 팀이 지정**하고 중복 버전이 생기지 않도록 한다.

## 2. 작성 규약
1. 본문 한국어, DB/API 필드·상태·코드 식별자는 원어 유지.
2. 사실은 `KNOWN`, 추론은 `RISK`, 실행 전은 `TO_VERIFY`로 분리.
3. 설계 문서: 목적→현행→대안→선택→트레이드오프→수용기준→롤백.
4. `ADR Accepted` 변경은 기존 문서 덮어쓰지 않고 새 ADR 링크로 supersede.
5. 지표는 측정 환경·샘플 크기·측정 명령·시점을 같이 저장.
6. 전화번호·실명·PG 시크릿·access token·실제 거래원문을 예시로 남기지 않는다.

## 3. 추천 도구(도입 전 상태)
| FE | BE | 공통 |
|---|---|---|
| 기존 Vue CLI/ESLint, 이후 Vite | `pytest`, `pytest-cov`, `ruff` (선택: Black), `mypy`(점진) | GitHub Actions, PR 보호, CODEOWNERS |
| Vitest(점진), Playwright(E2E) | SQLAlchemy/MySQL 통합 테스트, Alembic/Flask-Migrate | Docker Compose, OpenAPI, 시크릿 스캔 |
| npm audit/lockfile 검증 | `pip-audit`(또는 Dependabot), 의존버전 고정 | 환경변수 example·배포 승인 게이트 |

## 4. CI 도입 단계
**S1 (첫 2주)**
- FE job: `npm ci` → `npm run lint` → `npm run build` (현재 package.json에 명령 존재).
- BE job: 고정된 개발 Python 버전에서 `pip install -r requirements.txt` → 기본 import 검증 → **작성한 테스트가 생긴 후** `pytest`. 테스트 파일 없는데 pytest 성공으로 무조건 표시하지 말 것.
- GitHub secrets 검사/의존성 검토, PR 표준 템플릿, 두 저장소 기본 branch protection.

**S2 (주문 안정화)**
- MySQL 컨테이너 기반 integration test: migration up → seed → 주문/취소/동시 요청 → 정합성 조회.
- OpenAPI lint + FE 소비자 계약 테스트(스키마/상태/오류코드).

**S3 (배포/파일럿)**
- Playwright: QR 메뉴→주문→캐셔 승인→서빙→내역, 권한 없는 호출 403, 취소와 품절.
- Staging deploy + smoke test, 마이그레이션 사전 승인, 백업 복원 체크리스트.

**S4 (운영/심화)**
- 요청 ID/주문 ID 기반 로그, 오류율·5xx·DB connection·SSE 연결 수 알림.
- 모의 결제 대사와 ERP 실패 자동 감지/재처리 작업(구현 단계 이후).

## 5. Python 테스트 실행 권장(현재 그대로 복사해 실행 가능한 명령이라는 의미 아님)
```
# 새 테스트 의존성과 설정을 먼저 추가한 뒤
python -m pytest -q
python -m pytest tests/integration -q
# DB/마이그레이션 명령은 팀이 실제 앱 경로와 도구를 결정해 고정
```
CI config는 두 저장소의 실제 빌드/DB 환경에서 통과시킨 후 Required Status Checks로 지정한다. 본 문서의 명령은 **목표 상태**이며 현재 저장소에 존재하지 않는 도구도 포함된다.

## 6. 문서 자동화 목표
- OpenAPI 변경 PR에서 lint/호환성 검사 → FE 생성 타입/클라이언트와 계약 테스트.
- ORM 모델 변경 시 migration 누락 검사 및 임시 DB에서 migration up 검증.
- 배포 릴리즈에 merged PR 기반 변경 기록 초안; 담당자가 내용과 영향 검증.
- 외부 연동/모의 정산 불일치는 익명화한 Issue 자동 작성(중복 그룹화). 실제 거래 로그 자동 업로드 금지.
- ADR, 결제·권한 정책은 AI나 CI가 **자동 승인할 수 없다**.

## 7. AI와 IDE 사용 규칙
- Antigravity/VS Code 등의 생성 도구는 초안/테스트 아이디어/리팩터링 보조로 사용. PR 작성자는 생성 부분과 사람이 실행한 검증을 구분.
- 로그인 자격정보·개인정보·결제 응답 원문·운영 .env는 외부 AI에 입력 금지.
- AI가 제안한 트랜잭션 잠금/DB Migration은 실제 MySQL 환경에서 동시성·롤백 테스트를 거쳐야 병합.
- AI 코드 리뷰 자동 승인 및 운영 브랜치 직접 배포 권한 제공 금지.

## 8. 모니터링·데이터 유지 규칙
- 고객 데이터 최소 수집(전화번호 필요성 재검토), 정해진 보유기간·접근권한·삭제 프로세스.
- 주문 상태/금액 변경 로그는 누가/언제/이유/원 거래 ID 중심, 개인정보와 비밀값을 제외한 참조 식별자만 수집.
- DB 백업에 고객 데이터가 포함되므로 암호화 및 만료·복원·접근 통제를 문서화.
