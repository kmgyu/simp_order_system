# As-Is 통합 코드 점검 — FE + Flask BE (v0.2)

- 검토일: 2026-10-14, 브랜치: 두 저장소의 `main`
- 방법: 공개 소스 파일/README/트리 **정적 분석**; 런타임·DB 스키마 실제 생성·API 왕복·동시성은 검증 전.
- FE: https://github.com/Capybara-Clinic/mnu_pub_order_system
- BE: https://github.com/Capybara-Clinic/capybara-qr-order
- 분류: **KNOWN(확인한 구현 사실)** / **RISK(영향 가능성)** / **TO_VERIFY(구동 검증 과제)**.

## 1. 실제 기술 및 구현 구성
| 구분 | 사실 | 근거 파일 |
|---|---|---|
| FE | Vue 3, Vue Router, Pinia, Vue CLI, Tailwind; 화면 일부는 API·SSE, 일부는 Pinia 더미 데이터 | `front-end/package.json`, `src/services/api.js`, `src/stores/*`, `src/pages/*` |
| BE | Flask 3.1.1 + SQLAlchemy 3.1.1 + PyMySQL + MySQL 연결 문자열 | `requirements.txt`, `config.py` |
| BE 모듈 | 메뉴, 주문, 캐셔, 주방, 서빙 5개 Blueprint | `app/__init__.py`, `app/routes/` |
| DB 모델 | `Category`, `Menu`, `StoreTable`, `Order`, `OrderDetail`, `Payment`, `QRCode` 7개 | `app/models/__init__.py` |
| 결제 | 주문 등록은 `결제대기`, 캐셔 확인은 `Order.order_status`만 `결제확인`으로 갱신 | `app/routes/order.py`, `app/routes/cashier.py` |
| 실시간 | 메뉴/주방/서빙 SSE가 DB 주기 조회·sleep(3초) | `app/routes/menu.py`, `kitchen.py`, `serving.py` |
| 배포 | `run.py`에 `app.run(debug=True, host="0.0.0.0", port=3000)` | `run.py` |
| 협업 | 백엔드 README에 커밋 규칙은 있으나 자동 테스트/CI·Migration 파일은 트리에서 미발견 | BE README, 파일 트리 |
| 라이선스 | FE에는 MIT LICENSE 있음. BE 저장소 트리에는 LICENSE가 확인되지 않음 | 두 저장소 최상위 파일 트리 |

## 2. 우선 기술 리스크 및 재현 계획
| ID | 중요 | 코드 근거(KNOWN) | 예상 영향(RISK) | 실험/수정 수용 기준 |
|---|---|---|---|---|
| A01 | **P0** | `app/routes/order.py` 주문 생성 시 Menu 재고 미차감; `cashier.py:cancel_order`에서 재고 증가 | 취소를 통한 재고 부풀림 | 재고 10→3 주문→취소 시 최종 10, 재취소 변화 없음 |
| A02 | **P0** | 주문에서 수량 `int(...)`만 변환, 양수·재고 한도 검증 부재 | 음수/초과 주문 및 음수 금액 가능 | 0, 음수, 초과 수량 4xx + 상태 불변 |
| A03 | **P0** | 관리자/캐셔/재고 POST/PATCH/DELETE에 인증·매장 권한 검증 코드 없음 | 비인가 주문 변경/재고 조작 | 익명 직접 API 접근 거부, 직원 RBAC 통과 |
| A04 | **P0** | 주문 생성·수동주문·주문 수정 중간에 오류 응답 리턴, 명시적 rollback 없음 | 세션 라이프사이클/예외 경계 혼란; 커밋 전 상태 관리 취약 | 실패 사례에서 주문·상세·재고 동시 롤백 검증; try/except 명시화 |
| A05 | **P0** | 주문 요청/응답에 멱등키 없음 | 네트워크 재시도/중복 클릭으로 주문 중복 | 동일 키/동일 본문 동시 20건→주문 1건; 다른 본문 동일 키는 충돌 |
| A06 | **P0** | `confirm_order()`는 `Order.order_status`만 변경, `Payment` 레코드 생성·갱신 없음 | 결제·매출·환불 대사 불가능 | 주문 결제 상태/거래 기록의 일관된 커밋, 조작권한 검사 |
| A07 | **P0** | `update_order_status()`가 지정된 네 상태라면 이전 상태와 무관하게 변경 | 취소→결제확인 같은 역전이 허용 | 상태 전이 테이블 테스트, 비정상 전이 409/422 |
| A08 | **P1** | 테이블 회차를 `Order.created_at >= StoreTable.updated_at`으로 필터 | 점유 상태변경과 주문 시각 경계 충돌, 과거/현재 혼선 | `table_sessions` FK 기반 명시적 이용 회차 |
| A09 | **P1** | `kitchen.py`, `serving.py` SSE는 `order_id > last_sent_id` 조건 | 기존 주문 상태 변화/서빙 변화는 추가 이벤트로 감지 어려움 | 초기 snapshot + 변경 이벤트/재연결 복구 검증 |
| A10 | **P1** | FE `inventoryStore`가 2초 기다린 뒤 프론트 상태 변경 | FE/BE 재고 원천 충돌 | UI 업데이트는 API 성공·서버 조회에만 반영 |
| A11 | **P1** | FE `CashierDashboard`가 Pinia 주문/결제 직접 삭제/수정 | 한 사용자의 UI만 바뀌며 서버 DB와 불일치 | 서버 API 명령 + 일관된 조회 방식으로 변경 |
| A12 | **P1** | FE README API 경로와 `api.js`·BE 실제 경로 차이; FE가 전달한 phoneNumber 직렬화되지 않음 | 명세 드리프트·업무 정보 미수신 | API 매트릭스, 계약 테스트, 개인정보 필드 최소화 |
| A13 | **P0** | `run.py` debug=True 및 전역 `CORS(app)`; `Config.SECRET_KEY` 기본값 `default-secret` | 배포 설정·CORS·세션 보안 취약 | 운영 debug=False, 비밀키 필수, 허용 origin 명시 |
| A14 | **P1** | 주문 상세 반환에서 `menu_name`을 현재 메뉴 레코드에서 참조 (`cashier.py` 등) | 메뉴명 변경 후 이전 주문의 표시명 변동 | 주문 시 메뉴명·단가 스냅샷 저장·조회 |
| A15 | **P0(조사)** | BE 저장소 트리에 LICENSE 없음 | 라이선스·저작권 불확실성 | 기여자 권리/재사용 승인 및 LICENSE 결정 |
| A16 | **P1** | `menu.py: /stocks` 응답 필드 `meun_price` 오탈자 | FE/API 호환성 오류 | 계약 검사 및 오탈자 전환 계획 |

> A04는 즉시 "잔여 미커밋 데이터가 무조건 저장된다"고 단정할 수 없다. 요청 종료의 세션 제거가 rollback할 수 있다. **문제는 명시적 트랜잭션 경계·복구 계약이 없다는 점**이며 실제 결과를 테스트해야 한다.

## 3. API/DB 불일치 메모
- FE API는 `VUE_APP_API_BASE_URL`을 사용하고 BE는 `run.py`의 3000포트로 실행됨. README 예시 5000과 통합 환경 변수를 확인해야 함.
- FE `submitOrder({phoneNumber})`는 `api.js` 본문 직렬화에서 제거되며 BE `submit_order()`도 전화번호를 받지 않는다. 수집 필요성을 먼저 검토.
- BE `order.py`가 기록하는 가격은 서버 `Menu.price`를 사용한다(좋은 출발점). 다만 가격변경 시 이전 주문의 이름 스냅샷은 별개 문제.
- `Payment` 모델은 있으나 결제 생성/환불 처리 API 코드는 검토 범위 내 미발견. **없다는 사실을 런타임 전체에 대한 단정으로 확대하지 않는다**.
- DB 컬럼은 MySQL 계열 `Enum`·`Numeric`; `stock_quantity` nullable, 재고 무제한과 품절 정책을 명확히 구분해야 한다.
- FE는 고정 테이블 10개 mock, BE에는 QR 코드 12개 이미지와 `StoreTable` 모델. 실제 DB row/현장 테이블 수는 미확인.

## 4. 첫 2주 조사 과제 — 완료 증거
1. BE DB 스키마 생성 SQL/샘플 데이터를 확보해 개발 환경에 복원(실제 고객 데이터 금지).
2. FE와 BE를 Compose 네트워크로 실행하고 `메뉴 조회→주문→캐셔 확인→서빙` 왕복 기록.
3. A01~A07 테스트 작성: 현재 실패(expected red)→수정 후 green을 PR에 첨부.
4. OpenAPI의 v0 계약 작성(구현에 맞춘 기록). 앞으로 변경할 계약 v1은 별도 설계.
5. 저장소 권리·LICENSE·기여자 확인 후 모노레포 여부 결정.
6. DB에 실제 `payments` 데이터가 들어가는 경로 및 저장 시점 조사.

## 5. 바로 고치지 않는 항목
Vue CLI→Vite, Flask→Spring, MySQL→PostgreSQL, SSE→Kafka 변경은 우선순위 P0 작업이 아니다. 현재 사용자 흐름·보안·데이터 안정성을 확보한 뒤 별도 ADR과 측정 근거로 진행한다.
