# 아키텍처: 현행 Flask를 도메인 중심으로 정비 (v0.2)

## 1. 원칙 / AS-IS
- 현재 BE는 `app/routes/`의 메뉴·주문·캐셔·주방·서빙 Blueprint에서 SQLAlchemy 모델을 직접 조작한다. `app/models/__init__.py`에 7개 모델이 정의되어 있다.
- FE에는 Vue SPA, Pinia mock, `api.js` HTTP 모듈이 공존한다.
- **권장 초기안:** Flask 3 + SQLAlchemy + MySQL 계열 DB 유지, Vue 3 유지. 컴포넌트/도메인별 패키지와 서비스 계층을 추가하는 **모듈러 모놀리스**.
- Flask→Spring Boot, MySQL→PostgreSQL은 *필요성·팀 역량·이관 비용*에 근거한 ADR 통과 시 별도 진행. 즉시 재구축하지 않는다.

## 2. 1차 권장 구성
```
          [고객 Vue QR UI]      [점주/직원 Vue UI]
                     \           /
               [HTTPS / Proxy]
                       |
              [Flask REST API]
                       |
       [Auth/RBAC + Store Scope + Validation]
                       |
  [MenuService] [OrderService] [InventoryService]
  [PaymentService] [TableSession] [ReportingService]
                       |
                [SQLAlchemy]
                       |
                [MySQL / MariaDB]
                       |
         [Outbox DB table + worker (P2)]
                       |
        [Mock PG / PG sandbox / ERP CSV]
```

**현재 2개 저장소 유지**: 개발자 로컬에서 별도 체크아웃 후 통합 compose, 환경 파일 `env.example`로 설정을 재현한다. 별도 `deployment`/`infra` 저장소를 만드는 것은 선택 사항. 라이선스 및 협업 권한 확인 전 코드 복사를 전제하지 않는다.

## 3. 개선 후 BE 패키지 예시(아직 존재하지 않음)
```
app/
  __init__.py
  core/             # config, exceptions, db, auth, request ids
  models/           # ORM entities
  routes/           # 입력/응답 직렬화와 인증, 서비스 호출만
  schemas/          # Pydantic 또는 Marshmallow: 제안 (택1)
  services/         # order, inventory, payment, table_session, store
  repositories/     # 복잡한 데이터 접근(필요할 때만)
  workers/          # outbox/ERP/대사(2차 단계)
  tests/            # unit / integration / contract
migrations/         # Alembic or Flask-Migrate
```
- 과도한 계층화 지양. 주문·재고·결제 경계부터 분리한다.
- `Db session` 생명주기와 commit/rollback 책임을 한곳(서비스/unit-of-work)에서 관리한다.
- API 라우트에서 직접 DB 상태 변경 후 여러 번 commit하는 패턴을 제거한다.

## 4. 상태 모델과 변경 규칙
| 도메인 | 권장 상태(예시) | 경계 |
|---|---|---|
| Order | `PLACED`→`ACCEPTED`→`PREPARING`→`SERVED`, 별도 `CANCELLED` | 주문 수락/취소 정책 |
| Payment | `UNPAID`→`PENDING`→`PAID`, `FAILED`, `PARTIAL_REFUND`, `REFUNDED` | 수동 확인 또는 PG 거래 사건 기록 |
| Inventory | 수량+증감 원인(`SALE`, `CANCEL`, `MANUAL_ADJUST`) | 조건부 수량 업데이트/Lock |
| TableSession | `OPEN`→`CLOSED` | 고객 이용 회차 단위 주문 FK |
| Store | `OPEN`/`PAUSED`/`CLOSED` | 신규 주문 가능성 |
- 기존 한국어 Enum `결제대기/결제확인/완료/취소`는 새 상태로 무조건 한 번에 변환하지 않는다. 읽기/쓰기 어댑터와 Migration을 병행하고 옛 API 폐기 일자를 합의한다.
- Payment의 저장 시점: 수동 입금 확인도 Payment record와 감사로그를 *같은 DB 트랜잭션*에서 갱신한다. 실제 외부 결제 완료 여부와 관리자의 수동 확인을 혼동하지 않는다.

## 5. 주문 생성 / 재고 차감 원자성(안)
1. 요청 도메인 검사: 인증 매장/테이블 범위, `quantity > 0`, 메뉴 현재 판매 여부, 동일 `Idempotency-Key`와 요청 해시.
2. DB 트랜잭션 시작: 해당 키와 요청 해시를 고유 제약 하에 등록하거나 기존 결과 조회.
3. 서버에서 메뉴/옵션 가격 및 권한 재검증; `order_items`에 상품명/가격 스냅샷 저장.
4. `UPDATE menus SET stock_quantity=stock_quantity - :qty WHERE menu_id=:id AND stock_quantity>=:qty` 등의 조건부 업데이트(정확한 SQL·영향행수 검사 필요) 또는 `SELECT ... FOR UPDATE`로 잠금. 여러 상품이면 일관된 순서로 잠금하여 데드락 최소화.
5. 주문·상세·재고이력·멱등 요청 기록·감사 이벤트 저장 후 **한 번에 commit**.
6. 검증 오류/DB 예외는 전체 rollback; 데드락/격리 오류는 **유한 횟수**로 안전한 멱등 재시도.
7. 커밋 후 UI에 주문 ID 반환. 응답 유실 시 동일 멱등키 재조회.

**중요:** 무제한 재고 메뉴(`stock_quantity=NULL`)을 지원할지 여부를 명확히 결정한다. 유한 수량과 `NULL`을 섞어 사용할 경우 별도 분기/검사가 필요하다. 선결제와 사후결제의 재고 **예약 vs 즉시차감** 정책을 먼저 ADR로 확정하고, 선택한 정책에 맞춰 변경한다.

## 6. 주문·취소·환불 제어
- `cancel_order()`는 무조건 `stock_quantity += quantity` 하지 않는다. 해당 주문이 실제로 차감한 `inventory_movements`가 있는지 검사하고 1회만 보정한다.
- 수동결제 확인은 `Order`와 `Payment`를 함께 검증·변경, 결제확인자/시각을 기록한다.
- 결제 후 취소 요청은 주문 상태/승인/환불/재고 이동을 분리한다. 환불이 지연돼도 "환불완료"를 선반영하지 않는다.
- `PATCH status`는 역할/선행상태/동시 버전 검증 없이는 변경하지 못하도록 한다.

## 7. FE↔BE 데이터 소유권 정리
- `tableStore`/`inventoryStore`에 포함된 데모 초기값은 fixtures(테스트 데이터)로 분리; 운영 화면에서 최종 원천은 서버 API.
- 캐셔 테이블 정리는 FE 객체 delete가 아니라 BE 서비스 명령 + 조회/이벤트 반영.
- API 요청·응답 계약(`09_AS_IS_API_MATRIX.md`)에 맞춰 현재 구현을 먼저 고정하고 v1 변경 시 프론트와 서버를 같은 이슈로 묶는다.
- SSE는 유지해도 되지만 DB polling loop의 연결 수/커넥션 점유/재연결, 상태 변화 누락을 점검. 초기 snapshot + 재연결 조회 방식 우선. Redis/pub-sub 선도입 금지.

## 8. DB 데이터 모델: 진화식 확장
기존 7개 모델을 유지하는 동안 `order_details`에 `menu_name_snapshot` 추가, `payments`에 추적용 unique/status 보강, `table_sessions`, `inventory_movements`, `idempotency_requests`, `audit_logs`, `users/store_memberships` 등을 순차 도입한다. 이후 멀티매장 범위 확정 시 `stores`와 각 테이블의 `store_id` 추가. 상세는 `11_DB_MIGRATION_PLAN.md`.

## 9. 최소 API 계약(향후 설계, 미구현)
- `GET /api/v1/stores/{storeId}/menus`
- `POST /api/v1/stores/{storeId}/orders` + `Idempotency-Key`
- `GET /api/v1/orders/{orderId}` + 서버 권한 검증
- `POST /api/v1/stores/{storeId}/orders/{orderId}/cancel`
- `POST /api/v1/stores/{storeId}/inventory-adjustments`
- `POST /api/v1/orders/{orderId}/manual-payment-confirmations` (직원 전용)
- `POST /api/v1/stores/{storeId}/tables/{tableId}/sessions` / `.../{sessionId}/close`
- `PATCH /api/v1/stores/{storeId}/settings`

이는 기존 엔드포인트와 다른 **제안**이며 현재 서버가 제공하는 API라고 설명하면 안 된다. 최초에는 기존 경로에 접근 통제/테스트를 붙이는 최소 변경을 우선한다.

## 10. 운영·비기능 품질
- 테스트: pytest, pytest-flask(optional), MySQL Docker를 쓰는 DB 통합 테스트, 프론트 Vitest/Playwright(설정 후).
- Flask 보안 설정: debug=False(운영), fail-fast SECRET_KEY, 제한 CORS, 검증된 인증/권한, 로깅 마스킹.
- 마이그레이션: Alembic/Flask-Migrate + Expand/Migrate/Contract, 변경 실패 대비 백업 복원.
- 부하 관측: 트랜잭션 처리량/Lock wait/Slow query/SSE 연결수/5xx. SLO는 실제 측정 후 확정.
- 도구 의존도 최소화: 초기에는 단일 API+DB+프록시+CI로 충분. 복잡한 브로커는 outbox 규모/장애 요구가 생기면 논의.
