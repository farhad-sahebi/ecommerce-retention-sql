USE ecommerce_retention;

-- How much revenue does the company generate each month, and is it growing?
SELECT
    d.year,
    d.month,
    d.month_name,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.total_order_value) AS total_revenue,
    ROUND(AVG(f.total_order_value), 2) AS avg_order_value
FROM vw_fact_orders f
JOIN dim_date d
    ON f.purchase_date_key = d.date_key
WHERE f.order_status = 'delivered'
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

-- How much does a customer spend per order on average?
SELECT
    ROUND(AVG(total_order_value), 2) AS avg_order_value,
    ROUND(MIN(total_order_value), 2) AS min_order_value,
    ROUND(MAX(total_order_value), 2) AS max_order_value
FROM vw_fact_orders
WHERE order_status = 'delivered';

-- How much revenue comes from products vs freight?
SELECT
    ROUND(SUM(items_value), 2) AS product_revenue,
    ROUND(SUM(freight_value), 2) AS freight_revenue,
    ROUND(SUM(total_order_value), 2) AS total_revenue,
    ROUND(SUM(freight_value) / SUM(total_order_value) * 100, 2) AS freight_pct
FROM vw_fact_orders
WHERE order_status = 'delivered';

-- Is revenue accelerating or slowing down?
WITH monthly_revenue AS (
    SELECT
        d.year,
        d.month,
        SUM(f.total_order_value) AS revenue
    FROM vw_fact_orders f
    JOIN dim_date d ON f.purchase_date_key = d.date_key
    WHERE f.order_status = 'delivered'
    GROUP BY d.year, d.month
)
SELECT
    year,
    month,
    revenue,
    revenue - LAG(revenue) OVER (ORDER BY year, month) AS revenue_change,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY year, month)) /
        LAG(revenue) OVER (ORDER BY year, month) * 100, 2
    ) AS revenue_growth_pct
FROM monthly_revenue;