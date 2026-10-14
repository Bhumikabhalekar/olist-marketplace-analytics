USE olist_db;

-- ===== PART 1: INDEXES (make joins fast) =====
CREATE INDEX idx_orders_order_id   ON orders(order_id);
CREATE INDEX idx_orders_customer   ON orders(customer_id);
CREATE INDEX idx_items_order       ON order_items(order_id);
CREATE INDEX idx_items_product     ON order_items(product_id);
CREATE INDEX idx_reviews_order     ON reviews(order_id);
CREATE INDEX idx_customers_id      ON customers(customer_id);
CREATE INDEX idx_products_id       ON products(product_id);
CREATE INDEX idx_payments_order    ON payments(order_id);
CREATE INDEX idx_category_name     ON category_translation(product_category_name);