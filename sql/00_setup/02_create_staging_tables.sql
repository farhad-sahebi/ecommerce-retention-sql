-- Import dataset
USE ecommerce_retention;

-- Drop in correct dependency order (safe re-runs)
DROP TABLE IF EXISTS stg_order_items;
DROP TABLE IF EXISTS stg_orders;
DROP TABLE IF EXISTS stg_order_payments;
DROP TABLE IF EXISTS stg_customers;
DROP TABLE IF EXISTS stg_products;
DROP TABLE IF EXISTS stg_sellers;

-- 1) Customers
CREATE TABLE stg_customers (
    customer_id               CHAR(32)     NOT NULL,
    customer_unique_id        CHAR(32)     NOT NULL,
    customer_zip_code_prefix  INT          NULL,
    customer_city             VARCHAR(100) NULL,
    customer_state            CHAR(2)      NULL,
    PRIMARY KEY (customer_id),
    INDEX idx_customer_unique_id (customer_unique_id), -- We use INDEX in here it will speed up the searching for each customer id.
    INDEX idx_customer_state (customer_state) 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4; -- we use InnoDB a storage engine for reliable transactions and data integrity, and utf8mb4 as the as character set to support all language and sympols.

-- 2) Orders
CREATE TABLE stg_orders (
    order_id                         CHAR(32)     NOT NULL,
    customer_id                      CHAR(32)     NOT NULL,
    order_status                     VARCHAR(20)  NULL,
    order_purchase_timestamp         DATETIME     NULL,
    order_approved_at                DATETIME     NULL,
    order_delivered_carrier_date     DATETIME     NULL,
    order_delivered_customer_date    DATETIME     NULL,
    order_estimated_delivery_date    DATETIME     NULL,
    PRIMARY KEY (order_id),
    INDEX idx_orders_customer (customer_id),
    INDEX idx_orders_purchase_ts (order_purchase_timestamp),
    INDEX idx_orders_status (order_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3) Order Items (line level)
CREATE TABLE stg_order_items (
    order_id               CHAR(32)      NOT NULL,
    order_item_id          INT           NOT NULL,
    product_id             CHAR(32)      NOT NULL,
    seller_id              CHAR(32)      NOT NULL,
    shipping_limit_date    DATETIME      NULL,
    price                  DECIMAL(10,2) NULL,
    freight_value          DECIMAL(10,2) NULL,
    PRIMARY KEY (order_id, order_item_id),
    INDEX idx_items_product (product_id),
    INDEX idx_items_seller (seller_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4) Payments
CREATE TABLE stg_order_payments (
    order_id               CHAR(32)      NOT NULL,
    payment_sequential     INT           NOT NULL,
    payment_type           VARCHAR(20)   NULL,
    payment_installments   INT           NULL,
    payment_value          DECIMAL(10,2) NULL,
    PRIMARY KEY (order_id, payment_sequential),
    INDEX idx_payments_type (payment_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5) Products
CREATE TABLE stg_products (
    product_id                    CHAR(32)      NOT NULL,
    product_category_name         VARCHAR(100)  NULL,
    product_name_lenght           INT           NULL,
    product_description_lenght    INT           NULL,
    product_photos_qty            INT           NULL,
    product_weight_g              INT           NULL,
    product_length_cm             INT           NULL,
    product_height_cm             INT           NULL,
    product_width_cm              INT           NULL,
    PRIMARY KEY (product_id),
    INDEX idx_products_category (product_category_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6) Sellers
CREATE TABLE stg_sellers (
    seller_id               CHAR(32)     NOT NULL,
    seller_zip_code_prefix  INT          NULL,
    seller_city             VARCHAR(100) NULL,
    seller_state            CHAR(2)      NULL,
    PRIMARY KEY (seller_id),
    INDEX idx_sellers_state (seller_state)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Check the tables
SHOW TABLES LIKE 'stg_%';
