USE ecommerce_retention;

-- 0) Quick sanity check: how many real customers?
SELECT COUNT(DISTINCT customer_unique_id) AS distinct_real_customers
FROM vw_dim_customers;

--   What % of customers bought once vs returned?
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT f.order_id) AS order_count
    FROM vw_fact_orders f
    JOIN vw_dim_customers c
        ON f.customer_id = c.customer_id
    WHERE f.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time customers'
        ELSE 'Repeat customers'
    END AS customer_type,
    COUNT(*) AS customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM customer_orders
GROUP BY customer_type
ORDER BY customers DESC;

--   What % of customers purchased 2+ times?
SELECT
    ROUND(
        SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS repeat_purchase_rate_pct
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT f.order_id) AS order_count
    FROM vw_fact_orders f
    JOIN vw_dim_customers c
        ON f.customer_id = c.customer_id
    WHERE f.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) t;

--   How many orders does a customer place over their lifetime?
SELECT
    ROUND(AVG(order_count), 3) AS avg_orders_per_customer,
    MAX(order_count) AS max_orders_by_single_customer
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT f.order_id) AS order_count
    FROM vw_fact_orders f
    JOIN vw_dim_customers c
        ON f.customer_id = c.customer_id
    WHERE f.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) t;


--   In which month did each customer make their first delivered purchase?
DROP VIEW IF EXISTS vw_customer_cohorts;

CREATE VIEW vw_customer_cohorts AS
SELECT
    c.customer_unique_id,
    MIN(DATE(f.order_purchase_timestamp)) AS first_purchase_date,
    DATE_FORMAT(MIN(f.order_purchase_timestamp), '%Y-%m') AS cohort_month
FROM vw_fact_orders f
JOIN vw_dim_customers c
    ON f.customer_id = c.customer_id
WHERE f.order_status = 'delivered'
GROUP BY c.customer_unique_id;

-- Confirm cohort view is populated
SELECT COUNT(*) AS customers_in_cohorts
FROM vw_customer_cohorts;

--   For each cohort, how many customers are active in month 0,1,2,...?
SELECT
    coh.cohort_month,
    PERIOD_DIFF(
        DATE_FORMAT(f.order_purchase_timestamp, '%Y%m'),
        DATE_FORMAT(coh.first_purchase_date, '%Y%m')
    ) AS months_since_first_purchase,
    COUNT(DISTINCT dc.customer_unique_id) AS active_customers
FROM vw_fact_orders f
JOIN vw_dim_customers dc
    ON f.customer_id = dc.customer_id
JOIN vw_customer_cohorts coh
    ON dc.customer_unique_id = coh.customer_unique_id
WHERE f.order_status = 'delivered'
GROUP BY coh.cohort_month, months_since_first_purchase
ORDER BY coh.cohort_month, months_since_first_purchase;

--   What % of each cohort is retained over time?
WITH cohort_size AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_customers
    FROM vw_customer_cohorts
    GROUP BY cohort_month
),
retention AS (
    SELECT
        coh.cohort_month,
        PERIOD_DIFF(
            DATE_FORMAT(f.order_purchase_timestamp, '%Y%m'),
            DATE_FORMAT(coh.first_purchase_date, '%Y%m')
        ) AS months_since_first_purchase,
        COUNT(DISTINCT dc.customer_unique_id) AS active_customers
    FROM vw_fact_orders f
    JOIN vw_dim_customers dc
        ON f.customer_id = dc.customer_id
    JOIN vw_customer_cohorts coh
        ON dc.customer_unique_id = coh.customer_unique_id
    WHERE f.order_status = 'delivered'
    GROUP BY coh.cohort_month, months_since_first_purchase
)
SELECT
    r.cohort_month,
    r.months_since_first_purchase,
    r.active_customers,
    cs.cohort_customers,
    ROUND(r.active_customers * 100.0 / cs.cohort_customers, 2) AS retention_rate_pct
FROM retention r
JOIN cohort_size cs
    ON r.cohort_month = cs.cohort_month
ORDER BY r.cohort_month, r.months_since_first_purchase;
