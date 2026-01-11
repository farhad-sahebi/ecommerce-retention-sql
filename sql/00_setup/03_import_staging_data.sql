-- Connect session to database
USE ecommerce_retention;

-- secure_file_priv folder:
-- C:\ProgramData\MySQL\MySQL Server 9.5\Uploads\
-- Confirmed line ending works with: '\n'

-- Re-runnable (prevents duplicate key errors)
TRUNCATE TABLE stg_order_items;      -- make sure every table is empty and we can load data fresh withoud duplicates
TRUNCATE TABLE stg_order_payments;   
TRUNCATE TABLE stg_orders;
TRUNCATE TABLE stg_customers;
TRUNCATE TABLE stg_products;
TRUNCATE TABLE stg_sellers;

-- 1) CUSTOMERS
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.5/Uploads/olist_customers_dataset.csv' 	-- Load data from my computer
INTO TABLE stg_customers 																		-- Put that data in to specified table
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 														-- Each piece of data is parated by a comma enlcosed by double quotes (if there is a text, it's inside quotes)
LINES TERMINATED BY '\n'																		-- Each lines end with a new line terminated by backslash	
IGNORE 1 LINES																					-- Ignore one line
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state);		

-- 2) ORDERS (timestamp NULL handling)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.5/Uploads/olist_orders_dataset.csv'
INTO TABLE stg_orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, customer_id, order_status,
 @purchase_ts, @approved_at, @del_carrier, @del_customer, @est_delivery)
SET
order_purchase_timestamp      = NULLIF(@purchase_ts,''),
order_approved_at             = NULLIF(@approved_at,''),
order_delivered_carrier_date  = NULLIF(@del_carrier,''),
order_delivered_customer_date = NULLIF(@del_customer,''),
order_estimated_delivery_date = NULLIF(@est_delivery,'');

-- 3) ORDER ITEMS
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.5/Uploads/olist_order_items_dataset.csv'
INTO TABLE stg_order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, order_item_id, product_id, seller_id, @ship_limit, price, freight_value)
SET shipping_limit_date = NULLIF(@ship_limit,'');

-- 4) PAYMENTS
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.5/Uploads/olist_order_payments_dataset.csv'
INTO TABLE stg_order_payments
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, payment_sequential, payment_type, payment_installments, payment_value);

-- 5) PRODUCTS (FIXED: blanks -> NULL for INT columns)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.5/Uploads/olist_products_dataset.csv'
INTO TABLE stg_products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  product_id,
  product_category_name,
  @product_name_lenght,
  @product_description_lenght,
  @product_photos_qty,
  @product_weight_g,
  @product_length_cm,
  @product_height_cm,
  @product_width_cm
)
SET
  product_name_lenght         = NULLIF(@product_name_lenght,''),
  product_description_lenght  = NULLIF(@product_description_lenght,''),
  product_photos_qty          = NULLIF(@product_photos_qty,''),
  product_weight_g            = NULLIF(@product_weight_g,''),
  product_length_cm           = NULLIF(@product_length_cm,''),
  product_height_cm           = NULLIF(@product_height_cm,''),
  product_width_cm            = NULLIF(@product_width_cm,'');

-- 6) SELLERS
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.5/Uploads/olist_sellers_dataset.csv'
INTO TABLE stg_sellers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(seller_id, seller_zip_code_prefix, seller_city, seller_state);

-- VALIDATION (Row counts)
SELECT *
FROM (
    SELECT 'stg_customers'       AS tbl, COUNT(*) AS row_count FROM stg_customers
    UNION ALL
    SELECT 'stg_orders'          AS tbl, COUNT(*) AS row_count FROM stg_orders
    UNION ALL
    SELECT 'stg_order_items'     AS tbl, COUNT(*) AS row_count FROM stg_order_items
    UNION ALL
    SELECT 'stg_order_payments'  AS tbl, COUNT(*) AS row_count FROM stg_order_payments
    UNION ALL
    SELECT 'stg_products'        AS tbl, COUNT(*) AS row_count FROM stg_products
    UNION ALL
    SELECT 'stg_sellers'         AS tbl, COUNT(*) AS row_count FROM stg_sellers
) t
ORDER BY tbl;