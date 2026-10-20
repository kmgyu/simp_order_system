# As-Is FE ↔ BE API 대조표 (v0.2)

**코드 독해 기준 / 실호출 검증 전**. FE `front-end/src/services/api.js`와 BE `app/routes/*.py`, FE `README.md`를 대조. 이후 실제 OpenAPI 정본을 생성하기 전 출발점이다.

| 업무 | FE 현재 호출 | BE 실제 라우트(정적 확인) | 갭/우선 조치 |
|---|---|---|---|
| 메뉴 및 주문 조회 | `GET /menu/{tableId}` | `GET /menu/<int:table_id>` | 대체로 경로 일치; 반환 구조 UI 소비 검증 |
| 주문 생성 | `POST /order/submit` | `POST /order/submit` | 경로 일치. FE `phoneNumber` 인자 **본문 미전송**; 재고/수량/멱등 검증 추가 |
| 결제정보 조회 | `GET /order/payment_info/{orderId}` | 동일 | `order_id`를 안다고 타인 거래를 조회할 수 없도록 접근 통제 |
| 수동 결제 확인 | `POST /cashier/confirm_order` | 동일 | Payment 행 갱신 없음; 권한/중복 확인 추가 |
| 수동 주문 | `POST /cashier/manual_order` | 동일 | 상세 입력 검증, 재고/차감/권한 정책 |
| 주문 상태 | `PATCH /cashier/orders/{orderId}/status` | 동일 | 아무 선행 상태에서 네 상태로 변경 가능: 서버 상태 전이 차단 |
| 주문 수정 | `PUT /cashier/order/update` | 동일 | 기존 상세 삭제 후 재생성. 재고 차액/이력/가격 정책 및 입력 검증 필요 |
| 주문 취소 | `DELETE /cashier/order/delete` | 동일 | 취소 시 재고 증가, 주문시 미차감 문제; DELETE body 클라이언트 호환성 테스트 |
| 모든 테이블 | `GET /cashier/tables` | 동일 | `updated_at`로 현 세션 추정; DB 구조 개선 |
| 테이블 주문 | `GET /cashier/table/{tableId}` | 동일 | 타 테이블/고객 데이터 접근 제어 |
| 전체 주문 | `GET /cashier/ordermanagement` | 동일 | 전부 노출되는 관리자 API; 인증 필수 |
| 테이블 초기화 | `POST /cashier/tables/reset` | 동일 | `is_occupied=False`만 갱신; 세션/청구/취소 정책 필요 |
| 주방 | `GET /kitchen` | `GET /kitchen`(빈 suffix) | 새 주문 조회 정상 여부, 취소/상태 필터 테스트 |
| 서빙 | `GET /serving` | `GET /serving`(빈 suffix) | 역할 권한·상태 표시 검증 |
| 개별 서빙완료 | `POST /serving/complete` | 동일 | 주문 전체 완료와 함께 일관 트랜잭션 여부 테스트 |
| 전체 서빙완료 | `POST /serving/completeall` | 동일 | 이미 취소된 주문·결제대기 주문에 적용 불가 정책 필요 |
| 메뉴 SSE | `GET /menu/sse/{tableId}` | 동일 | 매 3초 DB 조회, 재연결·예외/리소스 검증 |
| 주방 SSE | `GET /kitchen/sse/` | `GET /kitchen/sse`(라우트 정의) | trailing slash 정규화 여부 테스트, 변경된 기존 주문 이벤트 누락 가능 |
| 서빙 SSE | `GET /serving/sse/` | `GET /serving/sse`(라우트 정의) | trailing slash 및 재연결, 변경 이벤트 문제 |
| 재고 수동 조회 | `GET /menu/{tableId}` 재호출 | `GET /menu/{tableId}` | FE 재고 스토어 별도 mock; 서버 기반 통일 |
| 재고 전체/업데이트 | FE `api.js`에는 직접 함수 미발견 | `GET /menu/stocks`, `POST /menu/stock/update` | API 브리지 필요; `meun_price` 오탈자·권한·수량 검증 |
| 품절 처리 | FE 함수 미발견 | `POST /menu/disable` | 점주 UI와 서버 연결 + 권한 |

### 추가로 직접 검증해야 하는 차이
1. **문서 드리프트**: FE README에 `GET /menu`와 `DELETE /cashier/order/{id}` 등 구 API가 있으나, 현재 FE 코드와 BE의 계약과 다름.
2. **서버 포트**: BE `run.py` 기본 3000, FE README는 API Base URL로 5000 표기. `VUE_APP_API_BASE_URL` 설정과 프록시/정적 배포 구성 확인 필요.
3. **라우트 접근 보호**: BE 라우트에 인증 decorator/사용자 권한 검사 없음. API 설계 시 추가.
4. **금액 타입**: BE SQLAlchemy `Numeric`, 응답에서 일부 `int`/`float` 변환. KRW 정수 단위, 소수 처리 정책 결정.
5. **SSE**: 연결 수, 재시도, 초기 동기화, 취소/서빙 상태 변경 이벤트가 FE에 전달되는지 시나리오 검사.
6. **재고 변경 후 화면**: BE 재고 변경과 FE `inventoryStore`의 mock 데이터가 자동으로 일치하지 않음.
7. **가격/상품명 스냅샷**: DB에 단가 스냅샷은 있지만 여러 조회가 현재 메뉴명을 읽음; 감사/리포트에는 당시 이름 저장 필요.
8. **개인정보**: 프론트에는 전화번호 입력이 있는데 서버 계약에 반영되지 않음. 수집을 추가하기 전에 필요성과 보유정책 결정.

### API 변경 규칙
- 0차: 현재 동작을 정확히 기록(`openapi-as-is.yaml`); 잘못된 동작도 사실로 기록하되 보안 위험은 공개 노출 금지.
- 1차: 위험한 API에 인증/입력 검증/상태 전이/멱등성 추가.
- 2차: `api/v1` 신규 경로에 매장 범위·에러 코드를 포함하고 FE 계약 테스트로 점진 이관.
- 3차: 구 라우트 제거는 FE 릴리즈·모바일 캐시·QR 배포 고려 후 수행.

**예시 에러 계약 제안(미구현)**: `400 VALIDATION_ERROR`, `401 UNAUTHENTICATED`, `403 FORBIDDEN`, `404 NOT_FOUND`, `409 STATE_CONFLICT`/`OUT_OF_STOCK`/`IDEMPOTENCY_CONFLICT`, `500 INTERNAL_ERROR` + `request_id`.
