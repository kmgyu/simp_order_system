# ADR-0003: 테이블 이용회차와 주문 이력

- Status: Proposed
- Date: 2026-10-14
- Owners: TBD

## Context
현재 테이블별 주문 검색은 `Order.created_at >= StoreTable.updated_at`으로 현재 회차를 추정한다. 테이블 수정시각은 주문 회차 식별자가 아니며 다른 이유로 갱신되면 과거/현재 이력이 혼재될 수 있다.

## Decision proposal
`table_sessions(id, table_id, store_id, opened_at, closed_at, status)`를 도입하고 `orders.table_session_id` FK를 추가한다. 새 고객 입장 시 새 회차를 생성하며, 테이블 정리는 회차 `CLOSED`로 표시한다. 과거 주문은 삭제하지 않는다.

## Validation
- 같은 테이블 2회차 주문이 서로 분리된 조회 결과를 반환.
- 과거 주문 취소/환불은 해당 회차·주문으로 추적.
- 동시에 두 회차를 여는 요청은 하나만 성공(필요한 unique/Lock 방식은 엔진에 맞게 결정).
- 기존 `updated_at` 추론 데이터 이관 시 정확하지 않은 이용회차는 추정으로 표시.
