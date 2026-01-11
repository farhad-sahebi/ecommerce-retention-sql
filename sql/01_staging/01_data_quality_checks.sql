USE ecommerce_retention;

-- 1) Duplicate key checks
SELECT 'customers_pk_dupes' AS check_name,
       COUNT(*) - COUNT(DISTINCT customer_id) AS issue_count
FROM stg_customers
UNION ALL
SELECT 'orders_pk_dupes',
       COUNT(*) - COUNT(DISTINCT order_id)
FROM stg_orders
UNION ALL
SELECT 'products_pk_dupes',
       COUNT(*) - COUNT(DISTINCT product_id)
FROM stg_products
UNION ALL
SELECT 'sellers_pk_dupes',
       COUNT(*) - COUNT(DISTINCT seller_id)
FROM stg_sellers;

-- 2) Orphan record checks (FK quality)
SELECT 'orders_missing_customer' AS check_name, COUNT(*) AS issue_count
FROM stg_orders o
LEFT JOIN stg_customers c 
ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT 'items_missing_order' AS check_name, COUNT(*) AS issue_count
FROM stg_order_items i
LEFT JOIN stg_orders o 
ON i.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT 'items_missing_product' AS check_name, COUNT(*) AS issue_count
FROM stg_order_items i
LEFT JOIN stg_products p 
ON i.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT 'items_missing_seller' AS check_name, COUNT(*) AS issue_count
FROM stg_order_items i
LEFT JOIN stg_sellers s 
ON i.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

SELECT 'payments_missing_order' AS check_name, COUNT(*) AS issue_count
FROM stg_order_payments pay
LEFT JOIN stg_orders o 
ON pay.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 3) Timestamp completeness
SELECT
  SUM(order_purchase_timestamp IS NULL) AS purchase_ts_nulls,
  SUM(order_approved_at IS NULL) AS approved_ts_nulls,
  SUM(order_delivered_customer_date IS NULL) AS delivered_customer_ts_nulls,
  SUM(order_estimated_delivery_date IS NULL) AS estimated_delivery_ts_nulls
FROM stg_orders;

-- 4) Numeric sanity checks
SELECT
  SUM(price < 0) AS negative_prices,
  SUM(freight_value < 0) AS negative_freight
FROM stg_order_items;

SELECT
  SUM(payment_value < 0) AS negative_payment_values,
  SUM(payment_installments < 0) AS negative_installments
FROM stg_order_payments;

-- 5) Quick distribution checks (useful later)
SELECT order_status, COUNT(*) AS orders
FROM stg_orders
GROUP BY order_status
ORDER BY orders DESC;

SELECT payment_type, COUNT(*) AS payments
FROM stg_order_payments
GROUP BY payment_type
ORDER BY payments DESC;