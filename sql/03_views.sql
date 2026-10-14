USE olist_db;

-- View 1: one row per order (delivery + review + revenue)
CREATE OR REPLACE VIEW vw_orders AS
WITH latest_review AS (
    SELECT order_id, review_score,
           ROW_NUMBER() OVER (PARTITION BY order_id
                              ORDER BY review_answer_timestamp DESC) AS rn
    FROM reviews
),
order_rev AS (
    SELECT order_id,
           SUM(price)         AS revenue,
           SUM(freight_value) AS freight,
           COUNT(*)           AS items
    FROM order_items
    GROUP BY order_id
)
SELECT
    o.order_id,
    c.customer_unique_id,
    c.customer_state,
    DATE(o.order_purchase_timestamp)                  AS order_date,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')  AS order_month,
    o.order_status,
    COALESCE(orv.revenue, 0)                          AS revenue,
    COALESCE(orv.freight, 0)                          AS freight,
    COALESCE(orv.items, 0)                            AS items,
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)   AS delivery_days,
    DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) AS delay_days,
    CASE WHEN o.order_delivered_customer_date IS NULL THEN NULL
         WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1
         ELSE 0 END                                   AS is_late,
    r.review_score
FROM orders o
JOIN customers c           ON o.customer_id = c.customer_id
LEFT JOIN order_rev orv    ON o.order_id = orv.order_id
LEFT JOIN latest_review r  ON o.order_id = r.order_id AND r.rn = 1;

-- View 2: one row per item sold (for category and state analysis)
CREATE OR REPLACE VIEW vw_sales_items AS
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.price,
    oi.freight_value,
    COALESCE(ct.product_category_name_english, 'unknown') AS category,
    DATE(o.order_purchase_timestamp)                  AS order_date,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')  AS order_month,
    c.customer_state
FROM order_items oi
JOIN orders o                       ON oi.order_id = o.order_id
JOIN customers c                    ON o.customer_id = c.customer_id
LEFT JOIN products p                ON oi.product_id = p.product_id
LEFT JOIN category_translation ct   ON p.product_category_name = ct.product_category_name;

-- View 3: one row per customer (for repeat purchase analysis)
CREATE OR REPLACE VIEW vw_customers AS
SELECT
    c.customer_unique_id,
    MIN(c.customer_state)          AS customer_state,
    COUNT(DISTINCT o.order_id)     AS n_orders,
    CASE WHEN COUNT(DISTINCT o.order_id) > 1 THEN 1 ELSE 0 END AS is_repeat
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id;