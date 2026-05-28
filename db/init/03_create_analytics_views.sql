-- ============================================================
-- EcoHome Supplies - Analytics Views
-- Project: business-ops-intelligence-hub
-- Database: business_ops
-- ============================================================

-- These views prepare raw business tables for Metabase dashboards.
-- They are normal SQL views, not materialized views.
-- This keeps the setup simple and rerunnable for the portfolio stage.


-- ============================================================
-- 1. Daily Revenue
-- Purpose:
-- Shows revenue and order count by day.
-- Useful for revenue-over-time charts.
-- ============================================================

CREATE OR REPLACE VIEW vw_daily_revenue AS
SELECT
    DATE(order_date) AS order_day,
    COUNT(order_id) AS order_count,
    SUM(total_amount) AS gross_revenue,
    ROUND(AVG(total_amount), 2) AS average_order_value
FROM orders
WHERE order_status NOT IN ('cancelled', 'refunded')
GROUP BY DATE(order_date);


-- ============================================================
-- 2. Product Sales Summary
-- Purpose:
-- Shows product-level sales performance.
-- Useful for top products, revenue by category, and product analysis.
-- ============================================================

CREATE OR REPLACE VIEW vw_product_sales_summary AS
SELECT
    p.product_id,
    p.sku,
    p.product_name,
    p.category,
    p.supplier_name,
    COALESCE(SUM(oi.quantity), 0) AS quantity_sold,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS gross_revenue,
    COALESCE(SUM(oi.discount_amount), 0) AS discount_total,
    COALESCE(SUM(oi.line_total), 0) AS net_revenue,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(AVG(oi.unit_price), 2) AS average_unit_price
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status NOT IN ('cancelled', 'refunded')
GROUP BY
    p.product_id,
    p.sku,
    p.product_name,
    p.category,
    p.supplier_name;


-- ============================================================
-- 3. Customer Order Summary
-- Purpose:
-- Shows customer-level buying behavior.
-- Useful for customer segmentation and repeat customer analysis.
-- ============================================================

CREATE OR REPLACE VIEW vw_customer_order_summary AS
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    c.country,
    c.city,
    c.customer_segment,
    c.marketing_consent,
    COUNT(o.order_id) AS order_count,
    COALESCE(SUM(o.total_amount), 0) AS total_spent,
    ROUND(
        COALESCE(SUM(o.total_amount), 0) / NULLIF(COUNT(o.order_id), 0),
        2
    ) AS average_order_value,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS last_order_date
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    AND o.order_status NOT IN ('cancelled', 'refunded')
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.country,
    c.city,
    c.customer_segment,
    c.marketing_consent;


-- ============================================================
-- 4. Inventory Reorder Alerts
-- Purpose:
-- Shows products that are close to or below reorder level.
-- Useful for inventory monitoring dashboards.
-- ============================================================

CREATE OR REPLACE VIEW vw_inventory_reorder_alerts AS
SELECT
    p.product_id,
    p.sku,
    p.product_name,
    p.category,
    i.quantity_on_hand,
    i.reorder_level,
    CASE
        WHEN i.quantity_on_hand <= i.reorder_level THEN TRUE
        ELSE FALSE
    END AS reorder_needed,
    CASE
        WHEN i.quantity_on_hand = 0 THEN 'out_of_stock'
        WHEN i.quantity_on_hand <= i.reorder_level THEN 'reorder_now'
        ELSE 'healthy'
    END AS stock_status,
    i.updated_at
FROM inventory i
JOIN products p
    ON i.product_id = p.product_id;


-- ============================================================
-- 5. Feedback Sentiment Summary
-- Purpose:
-- Summarizes customer feedback by product and sentiment.
-- Useful for customer experience dashboards and future AI analysis.
-- ============================================================

CREATE OR REPLACE VIEW vw_feedback_sentiment_summary AS
SELECT
    p.product_id,
    p.product_name,
    p.category,
    COUNT(cf.feedback_id) AS feedback_count,
    COUNT(cf.feedback_id) FILTER (
        WHERE cf.rating >= 4
    ) AS positive_count,
    COUNT(cf.feedback_id) FILTER (
        WHERE cf.rating = 3
    ) AS neutral_count,
    COUNT(cf.feedback_id) FILTER (
        WHERE cf.rating <= 2
    ) AS negative_count,
    ROUND(AVG(cf.rating), 2) AS average_rating,
    MAX(cf.feedback_date) AS latest_feedback_date
FROM products p
LEFT JOIN customer_feedback cf
    ON p.product_id = cf.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category;


-- ============================================================
-- 6. Competitor Price Comparison
-- Purpose:
-- Compares EcoHome product prices with competitor prices.
-- Useful for pricing dashboards.
-- ============================================================

CREATE OR REPLACE VIEW vw_competitor_price_comparison AS
SELECT
    p.product_id,
    p.sku,
    p.product_name,
    p.category,
    p.unit_price AS our_price,
    cp.competitor_name,
    cp.competitor_price,
    p.unit_price - cp.competitor_price AS price_difference,
    CASE
        WHEN cp.competitor_price > p.unit_price THEN 'we_are_cheaper'
        WHEN cp.competitor_price < p.unit_price THEN 'competitor_is_cheaper'
        ELSE 'same_price'
    END AS price_position,
    cp.checked_at
FROM products p
JOIN competitor_prices cp
    ON p.product_id = cp.product_id;


-- ============================================================
-- 7. Sales Channel Summary
-- Purpose:
-- Shows order and revenue performance by sales channel.
-- Useful for comparing online store, marketplace, and manual invoice.
-- ============================================================

CREATE OR REPLACE VIEW vw_sales_channel_summary AS
SELECT
    sales_channel,
    COUNT(order_id) AS order_count,
    SUM(total_amount) AS gross_revenue,
    ROUND(AVG(total_amount), 2) AS average_order_value,
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date
FROM orders
WHERE order_status NOT IN ('cancelled', 'refunded')
GROUP BY sales_channel;


-- ============================================================
-- End of analytics views
-- ============================================================
