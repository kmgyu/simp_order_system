-- ============================================================
-- Capybara QR Order: MySQL 초기 스키마 (DDL)
-- 기준: app/models/__init__.py 의 7개 SQLAlchemy 모델
-- ============================================================

CREATE DATABASE IF NOT EXISTS capybara_order CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE capybara_order;

-- 1. 카테고리 테이블
CREATE TABLE IF NOT EXISTS categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL,
    display_order INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. 매장 테이블
CREATE TABLE IF NOT EXISTS store_tables (
    table_id INT PRIMARY KEY,
    is_occupied BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. 메뉴 테이블
CREATE TABLE IF NOT EXISTS menus (
    menu_id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    menu_name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    price DECIMAL(10, 2) NOT NULL,
    image_url VARCHAR(255),
    is_available BOOLEAN DEFAULT TRUE,
    is_best_seller BOOLEAN DEFAULT FALSE,
    stock_quantity INT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_menus_category FOREIGN KEY (category_id) REFERENCES categories (category_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. 주문 테이블
CREATE TABLE IF NOT EXISTS orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    table_id INT,
    depositor_name VARCHAR(50) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    order_status ENUM('결제대기', '결제확인', '완료', '취소') DEFAULT '결제대기',
    order_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    order_number VARCHAR(10),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_orders_table FOREIGN KEY (table_id) REFERENCES store_tables (table_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. 주문 상세 테이블
CREATE TABLE IF NOT EXISTS order_details (
    order_detail_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    menu_id INT NOT NULL,
    quantity INT DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,
    is_served BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_details_order FOREIGN KEY (order_id) REFERENCES orders (order_id) ON DELETE CASCADE,
    CONSTRAINT fk_details_menu FOREIGN KEY (menu_id) REFERENCES menus (menu_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. 결제 테이블
CREATE TABLE IF NOT EXISTS payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_status ENUM('대기중', '완료', '환불', '취소') DEFAULT '대기중',
    is_verified BOOLEAN DEFAULT FALSE,
    payment_method ENUM('계좌이체', '기타') DEFAULT '계좌이체',
    check_time DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders (order_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. QR 코드 테이블
CREATE TABLE IF NOT EXISTS qr_codes (
    qr_id INT AUTO_INCREMENT PRIMARY KEY,
    table_id INT NOT NULL,
    qr_code_url VARCHAR(255) NOT NULL,
    redirect_url VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_qrcodes_table FOREIGN KEY (table_id) REFERENCES store_tables (table_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
