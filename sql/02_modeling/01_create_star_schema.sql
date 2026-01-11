USE ecommerce_retention;

-- A) DIM DATE (TABLE) - NON-RECURSIVE (COMPATIBLE)
DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date (
    date_key        INT         NOT NULL,      -- YYYYMMDD
    full_date       DATE        NOT NULL,
    year            SMALLINT    NOT NULL,
    quarter         TINYINT     NOT NULL,
    month           TINYINT     NOT NULL,
    month_name      VARCHAR(10) NOT NULL,
    day_of_month    TINYINT     NOT NULL,
    day_of_week     TINYINT     NOT NULL,       -- 1=Sunday ... 7=Saturday (MySQL DAYOFWEEK)
    day_name        VARCHAR(10) NOT NULL,
    week_of_year    TINYINT     NOT NULL,
    PRIMARY KEY (date_key),
    UNIQUE KEY uq_full_date (full_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Find min/max purchase date
SET @min_date := (SELECT MIN(DATE(order_purchase_timestamp))
                  FROM stg_orders
                  WHERE order_purchase_timestamp IS NOT NULL);

SET @max_date := (SELECT MAX(DATE(order_purchase_timestamp))
                  FROM stg_orders
                  WHERE order_purchase_timestamp IS NOT NULL);

-- Optional: verify min/max are not NULL
SELECT @min_date AS min_date, @max_date AS max_date;

-- Build a numbers set (0..4999 days) using cross joins
-- Covers ~13.7 years, enough for Olist range.
INSERT INTO dim_date (
    date_key, full_date, year, quarter, month, month_name,
    day_of_month, day_of_week, day_name, week_of_year
)
SELECT
    (YEAR(dt) * 10000) + (MONTH(dt) * 100) + DAY(dt) AS date_key,
    dt AS full_date,
    YEAR(dt) AS year,
    QUARTER(dt) AS quarter,
    MONTH(dt) AS month,
    DATE_FORMAT(dt, '%b') AS month_name,
    DAY(dt) AS day_of_month,
    DAYOFWEEK(dt) AS day_of_week,
    DATE_FORMAT(dt, '%a') AS day_name,
    WEEK(dt, 3) AS week_of_year
FROM (
    SELECT DATE_ADD(@min_date, INTERVAL n DAY) AS dt -- We need it Generate all calendar dates between the first and last order
    FROM (
        SELECT (a.n + b.n*10 + c.n*100 + d.n*1000) AS n  -- It combines digits from multiple small sets to generate a continuous sequence of numbers (n) used to create one date per day.
        FROM (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
        CROSS JOIN (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
        CROSS JOIN (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c
        CROSS JOIN (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) d
    ) nums -- It creates small sets of numbers (0–9 and 0–4) and cross joins them to generate all combinations, which are later combined to produce a sequence of numbers from 0 to 4999.
) dates
WHERE dt <= @max_date
ORDER BY dt;

-- B) DIMENSIONS (VIEWS)
DROP VIEW IF EXISTS vw_dim_customers;
CREATE VIEW vw_dim_customers AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM stg_customers;

DROP VIEW IF EXISTS vw_dim_products;
CREATE VIEW vw_dim_products AS
SELECT
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    (product_length_cm * product_height_cm * product_width_cm) AS product_volume_cm3
FROM stg_products;

DROP VIEW IF EXISTS vw_dim_sellers;
CREATE VIEW vw_dim_sellers AS
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM stg_sellers;

-- C) FACTS (VIEWS)
DROP VIEW IF EXISTS vw_fact_order_items;
CREATE VIEW vw_fact_order_items AS
SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value,
    (COALESCE(price,0) + COALESCE(freight_value,0)) AS item_total_value
FROM stg_order_items;

DROP VIEW IF EXISTS vw_fact_payments;
CREATE VIEW vw_fact_payments AS
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM stg_order_payments;

-- Fact orders: one row per order with aggregated financials and cycle-time metrics
DROP VIEW IF EXISTS vw_fact_orders;
CREATE VIEW vw_fact_orders AS
WITH item_agg AS (
    SELECT
        order_id,
        COUNT(*) AS item_count,
        COUNT(DISTINCT product_id) AS product_count,
        COUNT(DISTINCT seller_id) AS seller_count,
        SUM(COALESCE(price,0)) AS items_value,
        SUM(COALESCE(freight_value,0)) AS freight_value,
        SUM(COALESCE(price,0) + COALESCE(freight_value,0)) AS total_order_value
    FROM stg_order_items
    GROUP BY order_id
),
payment_agg AS (
    SELECT
        order_id,
        SUM(COALESCE(payment_value, 0)) AS total_payment_value,
        MAX(payment_installments) AS max_installments
    FROM stg_order_payments
    GROUP BY order_id
)
SELECT
    o.order_id,
    o.customer_id,
    o.order_status,

    o.order_purchase_timestamp,
    (YEAR(DATE(o.order_purchase_timestamp))*10000 + MONTH(DATE(o.order_purchase_timestamp))*100 + DAY(DATE(o.order_purchase_timestamp))) AS purchase_date_key,

    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    -- Cycle time metrics (days)
    CASE
        WHEN o.order_approved_at IS NULL OR o.order_purchase_timestamp IS NULL THEN NULL
        ELSE TIMESTAMPDIFF(DAY, o.order_purchase_timestamp, o.order_approved_at)
    END AS days_to_approve,

    CASE
        WHEN o.order_delivered_customer_date IS NULL OR o.order_purchase_timestamp IS NULL THEN NULL
        ELSE TIMESTAMPDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)
    END AS days_to_deliver,

    CASE
        WHEN o.order_delivered_customer_date IS NULL OR o.order_estimated_delivery_date IS NULL THEN NULL
        ELSE TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date)
    END AS delivery_delay_days,  -- positive = late, negative = early

    -- Financials
    COALESCE(i.item_count, 0) AS item_count,
    COALESCE(i.product_count, 0) AS product_count,
    COALESCE(i.seller_count, 0) AS seller_count,
    COALESCE(i.items_value, 0) AS items_value,
    COALESCE(i.freight_value, 0) AS freight_value,
    COALESCE(i.total_order_value, 0) AS total_order_value,

    COALESCE(p.total_payment_value, 0) AS total_payment_value,
    p.max_installments
FROM stg_orders o
LEFT JOIN item_agg i ON o.order_id = i.order_id
LEFT JOIN payment_agg p ON o.order_id = p.order_id;

-- D) QUICK CHECKS
SELECT
    COUNT(*) AS dim_date_rows,
    MIN(full_date) AS dim_date_min,
    MAX(full_date) AS dim_date_max
FROM dim_date;

SELECT *
FROM (
    SELECT 'vw_dim_customers' AS object_name, COUNT(*) AS row_count FROM vw_dim_customers
    UNION ALL
    SELECT 'vw_dim_products', COUNT(*) FROM vw_dim_products
    UNION ALL
    SELECT 'vw_dim_sellers', COUNT(*) FROM vw_dim_sellers
    UNION ALL
    SELECT 'vw_fact_order_items', COUNT(*) FROM vw_fact_order_items
    UNION ALL
    SELECT 'vw_fact_payments', COUNT(*) FROM vw_fact_payments
    UNION ALL
    SELECT 'vw_fact_orders', COUNT(*) FROM vw_fact_orders
) x
ORDER BY object_name;
