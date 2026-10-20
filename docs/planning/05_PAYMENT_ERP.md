# 결제·대사·ERP 심화 설계 — 기존 Payment 모델에서 출발 (v0.2)

## 1. 현재 구현과 갭
**As-Is KNOWN**: BE `Payment` 모델(금액, 상태, 검증 여부, 수단, 시각)이 정의됨. 반면 `app/routes/cashier.py:confirm_order()`에서는 `Order.order_status`만 `결제확인`으로 커밋한다. `app/routes/order.py:submit_order()`는 실제 결제 승인 없이 주문만 생성한다. 따라서 UI의 "결제완료" 문구가 외부 결제 성공을 증명해서는 안 된다.

## 2. 꼭 구분할 회계·업무 용어
- **주문**: 고객이 요청한 상품·수량·가격 스냅샷과 주문 상태.
- **결제/입금 확인**: 실제 결제기관의 승인/수동 확인. 주문 수락·조리 상태와 독립.
- **매출(판매/수익)**: 업무 정의(환불·세금·서비스 제공시점 포함)에 따라 계산하며 주문 합계와 다를 수 있음.
- **대사**: 내부 거래 기록 ↔ PG 거래/정산 내역의 차이를 확인하고 해결하는 업무.
- **정산**: 수수료·환불·지급 보류 등을 반영한 지급 금액/일정; 주문 원가/매출 합계와 다름.
- **ERP 연동**: 외부 회계·재고/전표 시스템에 합의된 형식으로 이벤트 또는 데이터를 전달하는 것.

## 3. 개발 순서
| 단계 | 시스템 | 반드시 다룰 예외 |
|---|---|---|
| 1 (P0) | 현장 입금 **수동 확인**을 Payment 기록으로 통합 | 중복 확인, 잘못된 금액, 결제 전/후 취소, 권한 |
| 2 (P2) | 외부 네트워크 없이 **Mock PG** | 승인/거절/타임아웃/중복 웹훅/순서 역전 |
| 3 (P2) | PG 제공 테스트 환경 | 서버 승인/금액 검증, 주문 ID↔PG 거래키 unique, 콜백 유실 |
| 4 (P2) | 환불과 정합성 | 부분환불 누계≤승인액, 재요청·환불 실패·수동 조정 감사 |
| 5 (P2) | 일마감 대사 | 영업일 vs 승인일 vs 지급예정일, 차액/미확정/중복 처리 |
| 6 (P2) | ERP CSV, 선택적 ERP API | 스키마 버전, SKU 매핑, 실패 재처리·중복 전송 방지 |

**금지**: 팀·PG 계약/약관·결제·개인정보 보안 검증 전 라이브 결제를 붙여서 실거래를 자동화하지 않는다.

## 4. 권장 데이터 구조
- `payment_attempts(id, order_id, amount, method, status, provider_key, idempotency_key, requested_at, confirmed_at)`.
- `payment_events(id, attempt_id, provider_event_id, event_type, payload_digest, received_at)`; 원문 비밀값 저장 금지.
- `refunds(id, payment_attempt_id, amount, status, external_refund_id, reason, idempotency_key)`.
- `daily_closings(id, store_id, business_date, computed_at, sales_total, refunds_total, exceptions_count)`.
- `reconciliation_runs(id, store_id, source, settlement_date, status, detected_count)` / `reconciliation_discrepancies(...)`.
- `outbox_events(id, aggregate_type, aggregate_id, event_type, payload, published_at, attempts)`.

초기에는 기존 `payments` 테이블을 버리거나 `Payment` 모델을 동시에 운영하지 말고 기존 데이터를 migration하는 단일 이력 체계를 먼저 정의한다. 결제 시도와 최종 결제 내역 사이 카디널리티(1:N)를 결정하고 스키마를 확정한다.

## 5. 정합성 시나리오 / Given-When-Then
1. 수동 입금 미확인 주문에 직원이 확인 2회 요청 → 최초 1회만 Payment confirmed, 두 번째는 멱등 응답 또는 전이 거부.
2. PG 승인 성공 응답이 유실 → `PENDING` 유지, PG 조회·웹훅으로 최종 확인, 중복 승인 금지.
3. 승인 금액 ≠ 서버 주문 확정 금액 → 결제 확정 거절/운영 사건 기록.
4. 동일 웹훅 두 번 전송 → 결제 이벤트 unique, 하나의 상태 변경만 적용.
5. 승인 10,000원, 부분환불 4,000원·6,000원 뒤 추가 환불 요청 → 0 초과 환불 거부.
6. 결제는 됐지만 주방 작업 전에 취소 → 별도 refund state와 재고 보상; 환불 성공 기록 없이 완료 처리 금지.

## 6. 모의 대사 예시(실제 계약과 무관한 가정)
승인 10,000원 / 부분환불 2,000원 / 가정한 수수료 300원 ⇒ 예상 지급 7,700원. 단, 수수료 계산, 부가세, 실제 수수료 환급 여부, 지급 주기 등은 PG 계약과 정산 데이터에 따라 달라진다. 매출 총액과 예상 PG 지급액은 **동일한 수치가 아니다**.

## 7. ERP 연동 계획
A. DB 거래 이벤트(`PaymentConfirmed`, `RefundCompleted`, `InventoryAdjusted`)를 Outbox에 기록(동일 DB 트랜잭션).
B. 워커가 CSV export 또는 ERP 어댑터 작업 생성. 단위 작업 고유키 `(external_system, event_id, schema_version)`.
C. 영구 오류(잘못된 상품/계정 코드)는 수정 대기, 일시 오류(503/timeout)는 지수백오프 재시도, 사후 재처리 내역 보존.
D. `schema_version`, 매장코드, 영업일, 원 주문번호, 거래유형, 금액·세금·수수료·환불과 SKU 코드 매핑을 명시.
E. CSV는 파일명 기준이 아니라 **전송 배치 ID와 거래 ID**로 중복 여부를 판단한다. ERP 수신처가 멱등성을 지원하지 않으면 재전송 전 중복 조회/수동 확인.

## 8. 상업·법적 경계
1차는 **매장이 판매 주체, 플랫폼은 주문·운영 SW 제공자**라는 모델을 우선 가정. 플랫폼이 결제대금을 통합 수납 후 여러 판매자에게 배분하는 방식은 라이선스·계약·전자금융/개인정보/세금 검토가 필요한 별도 프로젝트다. 본 문서는 법률·회계 자문이 아니다.

참고 자료(접속/정책은 실제 사용 전 재검증):
- 결제: https://docs.tosspayments.com/guides/v2/get-started/payment-flow
- 결제취소: https://docs.tosspayments.com/guides/v2/cancel-payment
- API 키: https://docs.tosspayments.com/reference/using-api/api-keys
- 지급대행: https://docs.tosspayments.com/guides/v2/payouts
