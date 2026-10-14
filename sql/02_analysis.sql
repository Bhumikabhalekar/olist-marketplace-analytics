USE olist_db;

-- Q1a: Monthly revenue, orders and average order value
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    ROUND(SUM(oi.price), 2)                          AS revenue,
    COUNT(DISTINCT o.order_id)                       AS orders,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY order_month
ORDER BY order_month;

-- Q1b: Month-over-month revenue growth (window function)
WITH monthly AS (
    SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
           SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY order_month
)
SELECT order_month,
       ROUND(revenue, 2) AS revenue,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY order_month))
             / LAG(revenue) OVER (ORDER BY order_month) * 100, 1) AS mom_growth_pct
FROM monthly;

-- Q2a: Top 10 categories by revenue
SELECT ct.product_category_name_english AS category,
       ROUND(SUM(oi.price), 0)          AS revenue
FROM order_items oi
JOIN products p              ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
GROUP BY category
ORDER BY revenue DESC
LIMIT 10;

-- Q2b: Top 10 states by revenue
SELECT c.customer_state AS state,
       ROUND(SUM(oi.price), 0) AS revenue
FROM order_items oi
JOIN orders o    ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY state
ORDER BY revenue DESC
LIMIT 10;

-- Q3a: Late delivery rate
SELECT ROUND(100 * AVG(order_delivered_customer_date > order_estimated_delivery_date), 1) AS late_pct
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

-- Q3b: Review score for late vs on-time orders
WITH latest_review AS (
    SELECT order_id, review_score,
           ROW_NUMBER() OVER (PARTITION BY order_id
                              ORDER BY review_answer_timestamp DESC) AS rn
    FROM reviews
)
SELECT
    CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
         THEN 'Late' ELSE 'On time' END AS delivery_status,
    COUNT(*)                        AS reviews,
    ROUND(AVG(r.review_score), 2)   AS avg_score
FROM orders o
JOIN latest_review r ON o.order_id = r.order_id AND r.rn = 1
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;

-- Q4: Repeat customers
WITH cust AS (
    SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS n_orders
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT COUNT(*)                           AS customers,
       SUM(n_orders > 1)                  AS repeat_customers,
       ROUND(100 * SUM(n_orders > 1) / COUNT(*), 1) AS repeat_rate_pct
FROM cust;

