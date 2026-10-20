# DB 변경 계획 — 기존 7개 SQLAlchemy 모델 기준 (v0.2)

## 1. 현재 모델(코드에 정의됨)
```
Category(category_id PK) 1─N Menu(menu_id PK, category_id FK)
StoreTable(table_id PK) 1─N Order(order_id PK, table_id FK)
Order 1─N OrderDetail(order_detail_id PK, order_id FK, menu_id FK)
Order 1─N Payment(payment_id PK, order_id FK) [FK는 존재, 1:1/1:N unique 보장은 명시되지 않음]
StoreTable 1─N QRCode(qr_id PK, table_id FK)
```
- `Menu`: `price Numeric(10,2)`, `stock_quantity Integer nullable`, `is_available Boolean`.
- `Order`: `total_amount Numeric(10,2)`, `order_status Enum(결제대기,결제확인,완료,취소)`.
- `OrderDetail`: `unit_price`, `subtotal` 스냅샷은 있음; `menu_name_snapshot` 없음.
- `Payment`: amount/status/is_verified/method/check_time는 있으나 실제 수동확인 라우트에서는 레코드 갱신 안 함.
- 다른 매장을 구분할 `stores/store_id`는 현재 모델에서 확인되지 않음.

## 2. 변경 정책
- MySQL 계열 DB를 기본으로 하되 **MariaDB 사용 여부/버전을 먼저 확인**한다. DB 서비스와 스키마를 실제 구동해야 정확한 DDL/락/Enum 변경 영향을 확정할 수 있다.
- Alembic 또는 Flask-Migrate를 선택하고 첫 migration을 실제 현재 schema 상태와 비교해 baseline한다. `db.create_all()`만으로 운영 스키마를 관리하지 않는다.
- Expand(새 컬럼/테이블) → Backfill(검증된 기존 데이터) → Dual read 또는 Compatibility adapter → Cutover → Contract(구 컬럼 제거) 순서.
- 멀티테넌트용 `store_id` 추가는 한 번의 migration에서 무조건 NOT NULL로 바꾸지 않는다. 기존 데이터 기본 매장 ID를 채우고 참조·FK·조회 범위를 검증한 뒤 강제한다.
- **백업+복원 테스트** 없이는 운영 데이터 변환 금지. 스키마 다운그레이드보다 forward-fix가 안전한 경우 수동 복원 절차를 문서화한다.

## 3. 순차 스키마 변경안
| 단계 | 추가·변경 대상 | 쓰임 | 선행 테스트 |
|---|---|---|---|
| M0 | 개발 DB baseline, schema dump, seed | 모든 개발자가 환경 재현 | 빈 DB/up, fixture 조회 |
| M1 | `inventory_movements`, 재고 null/유한 정책, 필요시 version | 차감·복원의 증빙/중복 방지 | TC01/02/08 |
| M2 | `idempotency_requests` 또는 `orders.idempotency_key`+해시+unique | 중복 제출 방지 | TC03/04 |
| M3 | `payment_events` 및 기존 `payments` 상태 정비 | 수동결제 확인 이력/상태 분리 | TC09/10 |
| M4 | `table_sessions`, `orders.table_session_id` | 이용 회차 구분 | TC13 |
| M5 | `order_details.menu_name_snapshot` | 주문 당시 이름 불변 | TC07 |
| M6 | `users`, `store_memberships`, `audit_logs` | 인증·RBAC·감사 | TC11/12 |
| M7 | `stores`, 주요 모델 `store_id`, 매장별 unique/index | 다중 매장 격리 | TC12(2개 매장) |
| M8 | `outbox_events`, `integration_jobs`, 정산/환불 | ERP/PG 심화 | TC15/16 |

**M6 보안 기능은 배포 전에 필수이며, 테이블 추가 순서상 더 앞당길 수 있다.** 파일럿의 단일 매장 모델이라도 사용자·직원 인증에 따른 접근 통제가 필요하다.

## 4. 기존 데이터 전환 포인트
1. 현재 주문의 가격/상품명: 새 스냅샷 채울 때 `Menu.menu_name`을 사용하는 데이터는 "당시 이름이 아닐 수 있음"을 표시한다. 과거를 확정적으로 복원했다고 말하지 않는다.
2. 재고: 과거 주문 생성에 차감 기록이 없으므로 과거 주문을 기준으로 **소급 차감/재복원하면 안 됨**. 운영 재고를 승인된 기준으로 재설정하고 baseline movement를 만든다.
3. Payment: 실제 수동 결제 확인 이력이 Order 상태에만 있으면 이전 데이터는 검증 근거가 부족하다. 과거 `결제확인`을 확정적인 외부 입금 증빙으로 변환하지 않는다.
4. 테이블 이용회차: `StoreTable.updated_at`으로 과거 세션 경계를 정확히 재구성할 수 없다면 불확실성을 보존/표시한다.
5. 주문번호: `Order.order_number`가 `String(10)`이고 unique 제약 미확인. 전환 시 중복·null 값 체크하고 `store_id/order_number` unique를 논의한다.

## 5. 인덱스와 제약 후보 (쿼리·측정 후 최종 결정)
- 주문 목록: `(store_id, created_at, order_id)`(멀티매장 도입 후).
- 주방 미처리: `(order_status, created_at)` 또는 매장 포함 복합 인덱스.
- `payment_attempts.provider_key` UNIQUE(공급자 범위 고려).
- `idempotency_requests(store_id, idempotency_key)` UNIQUE, 요청 본문 fingerprint 저장.
- `order_details(order_id)`, `payments(order_id)` FK 인덱스/행수 확인.
- 재고 이동의 `(order_id, movement_type, source_event_id)` 중복 방지 제약(정책에 맞춰 설계).
- 대용량 인덱스, nullable/Enum ALTER는 DB별 온라인 DDL·락 영향 테스트 후 적용.

## 6. Migration PR 완료 기준
DDL + ORM + 테스트·시드 수정 / 데이터 변경·백필 스크립트 / API 호환성 / 예상 락·배포시간 / staging 적용·복원 증거 / 롤백 또는 forward fix / 오너 승인.
