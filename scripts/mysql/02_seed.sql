-- ============================================================
-- Capybara QR Order: 로컬 개발 및 테스트용 시드 데이터 (Seed)
-- ============================================================

USE capybara_order;

-- 1. 매장 테이블 (1 ~ 12번)
INSERT INTO store_tables (table_id, is_occupied) VALUES
(1, FALSE),
(2, FALSE),
(3, FALSE),
(4, FALSE),
(5, FALSE),
(6, FALSE),
(7, FALSE),
(8, FALSE),
(9, FALSE),
(10, FALSE),
(11, FALSE),
(12, FALSE)
ON DUPLICATE KEY UPDATE is_occupied = VALUES(is_occupied);

-- 2. QR 코드 등록
INSERT INTO qr_codes (qr_id, table_id, qr_code_url, redirect_url) VALUES
(1, 1, '/static/qrcodes/table_1.png', 'http://localhost:8080/table/1'),
(2, 2, '/static/qrcodes/table_2.png', 'http://localhost:8080/table/2'),
(3, 3, '/static/qrcodes/table_3.png', 'http://localhost:8080/table/3'),
(4, 4, '/static/qrcodes/table_4.png', 'http://localhost:8080/table/4'),
(5, 5, '/static/qrcodes/table_5.png', 'http://localhost:8080/table/5'),
(6, 6, '/static/qrcodes/table_6.png', 'http://localhost:8080/table/6'),
(7, 7, '/static/qrcodes/table_7.png', 'http://localhost:8080/table/7'),
(8, 8, '/static/qrcodes/table_8.png', 'http://localhost:8080/table/8'),
(9, 9, '/static/qrcodes/table_9.png', 'http://localhost:8080/table/9'),
(10, 10, '/static/qrcodes/table_10.png', 'http://localhost:8080/table/10'),
(11, 11, '/static/qrcodes/table_11.png', 'http://localhost:8080/table/11'),
(12, 12, '/static/qrcodes/table_12.png', 'http://localhost:8080/table/12')
ON DUPLICATE KEY UPDATE redirect_url = VALUES(redirect_url);

-- 3. 카테고리 (1: 메인메뉴, 2: 사이드/탕, 3: 주류/음료)
INSERT INTO categories (category_id, category_name, display_order) VALUES
(1, '메인메뉴', 1),
(2, '사이드 및 탕류', 2),
(3, '주류 및 음료', 3)
ON DUPLICATE KEY UPDATE category_name = VALUES(category_name), display_order = VALUES(display_order);

-- 4. 메뉴 데이터
-- TC01, TC02, 품절, 무제한 재고 등 테스트 케이스를 위한 다양한 상태 포함
INSERT INTO menus (menu_id, category_id, menu_name, description, price, image_url, is_available, is_best_seller, stock_quantity) VALUES
-- 메인메뉴
(1, 1, '해물파전', '바삭하고 신선한 해물이 듬뿍 들어간 파전', 15000.00, 'https://images.unsplash.com/photo-1598514983318-2f64f8f4796c?w=500', TRUE, TRUE, 20),
(2, 1, '골뱅이소면', '새콤달콤 매콤한 양념에 쫄깃한 골뱅이와 소면', 16000.00, 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500', TRUE, TRUE, 15),
(3, 1, '치즈불닭', '화끈하게 매운 불닭과 고소한 모짜렐라 치즈', 18000.00, 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=500', TRUE, FALSE, 10),

-- 사이드 및 탕류
(4, 2, '어묵탕', '시원하고 깊은 국물의 수제 모둠 어묵탕 (TC01 재고 10개 테스트용)', 12000.00, 'https://images.unsplash.com/photo-1547592180-85f173990554?w=500', TRUE, FALSE, 10),
(5, 2, '치즈계란말이', '마지막 1개 한정 수량! 부드러운 치즈 달걀말이 (TC02 마지막 1개 동시성 테스트용)', 10000.00, 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=500', TRUE, FALSE, 1),
(6, 2, '참치마요주먹밥', '고소한 참치마요와 김가루가 듬뿍 들어간 주먹밥 (품절 테스트용)', 5000.00, 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500', FALSE, FALSE, 0),

-- 주류 및 음료 (무제한 재고: stock_quantity = NULL)
(7, 3, '참이슬', '깔끔하고 시원한 소주', 5000.00, 'https://images.unsplash.com/photo-1527281400683-1aae777175f8?w=500', TRUE, TRUE, NULL),
(8, 3, '카스 생맥주 500cc', '가슴 속까지 시원한 청량한 라거 맥주', 4500.00, 'https://images.unsplash.com/photo-1608270192842-887e5b5c96c4?w=500', TRUE, TRUE, NULL),
(9, 3, '콜라', '시원한 탄산음료 355ml', 2000.00, 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=500', TRUE, FALSE, NULL)
ON DUPLICATE KEY UPDATE 
    menu_name = VALUES(menu_name),
    price = VALUES(price),
    is_available = VALUES(is_available),
    stock_quantity = VALUES(stock_quantity);

-- 5. 샘플 주문 데이터 (초기 UI 대시보드 확인용 1건)
-- 1번 테이블에서 입금자 '홍길동', 결제대기 상태
INSERT INTO orders (order_id, table_id, depositor_name, total_amount, order_status, order_time, order_number) VALUES
(1, 1, '홍길동', 31000.00, '결제대기', NOW(), 'ORD-0001')
ON DUPLICATE KEY UPDATE total_amount = VALUES(total_amount);

INSERT INTO order_details (order_detail_id, order_id, menu_id, quantity, unit_price, subtotal, is_served) VALUES
(1, 1, 1, 1, 15000.00, 15000.00, FALSE),
(2, 1, 2, 1, 16000.00, 16000.00, FALSE)
ON DUPLICATE KEY UPDATE quantity = VALUES(quantity);

-- 1번 테이블 점유 상태로 갱신
UPDATE store_tables SET is_occupied = TRUE WHERE table_id = 1;
