-- ============================================================
-- EcoHome Supplies - Sample Business Data
-- Project: business-ops-intelligence-hub
-- Database: business_ops
-- ============================================================

-- This file seeds realistic sample data for a small sustainable
-- home-products e-commerce business.
--
-- It is designed to be rerunnable during early development.
-- TRUNCATE clears existing sample data and resets identities.

BEGIN;

-- ------------------------------------------------------------
-- Reset existing sample data
-- ------------------------------------------------------------
-- Order matters because of foreign keys.
-- CASCADE safely clears dependent rows.

TRUNCATE TABLE
    competitor_prices,
    customer_feedback,
    inventory,
    order_items,
    orders,
    products,
    customers
RESTART IDENTITY CASCADE;

-- ------------------------------------------------------------
-- 1. Products
-- ------------------------------------------------------------

INSERT INTO products (
    product_id,
    sku,
    product_name,
    category,
    supplier_name,
    unit_price,
    cost_price,
    is_active
)
VALUES
    (1, 'ECO-PC-001', 'Bamboo Toothbrush Set', 'Personal Care', 'GreenNest Supply Co.', 8.99, 3.20, TRUE),
    (2, 'ECO-KIT-002', 'Reusable Beeswax Wraps', 'Kitchen', 'EcoWrap Partners', 14.50, 6.10, TRUE),
    (3, 'ECO-CLN-003', 'Compostable Dish Sponges', 'Cleaning', 'PureHome Goods', 6.75, 2.40, TRUE),
    (4, 'ECO-CLN-004', 'Refillable Glass Spray Bottle', 'Cleaning', 'ClearCycle Manufacturing', 11.99, 4.80, TRUE),
    (5, 'ECO-LAU-005', 'Eco Laundry Detergent Sheets', 'Laundry', 'FreshLeaf Labs', 18.90, 7.50, TRUE),
    (6, 'ECO-KIT-006', 'Organic Cotton Produce Bags', 'Kitchen', 'GreenNest Supply Co.', 12.25, 5.10, TRUE),
    (7, 'ECO-KIT-007', 'Stainless Steel Lunch Box', 'Kitchen', 'EverSteel Home', 24.99, 11.40, TRUE),
    (8, 'ECO-STO-008', 'Reusable Silicone Food Bags', 'Storage', 'EcoWrap Partners', 19.99, 8.20, TRUE),
    (9, 'ECO-BTH-009', 'Natural Loofah Sponge', 'Bathroom', 'PureHome Goods', 5.99, 1.90, TRUE),
    (10, 'ECO-CLN-010', 'Wooden Dish Brush', 'Cleaning', 'ForestCraft Supply', 9.75, 3.60, TRUE),
    (11, 'ECO-HOM-011', 'Recycled Paper Towels', 'Cleaning', 'Circular Paper Co.', 13.40, 5.70, TRUE),
    (12, 'ECO-BAG-012', 'Biodegradable Trash Bags', 'Cleaning', 'PureHome Goods', 16.80, 7.00, TRUE);

-- ------------------------------------------------------------
-- 2. Customers
-- ------------------------------------------------------------

INSERT INTO customers (
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    country,
    city,
    customer_segment,
    marketing_consent,
    created_at
)
VALUES
    (1, 'Anna', 'Kowalska', 'anna.kowalska@example.com', '+48 501 100 201', 'Poland', 'Krakow', 'retail', TRUE, '2025-10-02 09:15:00+00'),
    (2, 'Marek', 'Nowak', 'marek.nowak@example.com', '+48 502 100 202', 'Poland', 'Warsaw', 'retail', FALSE, '2025-10-05 11:20:00+00'),
    (3, 'Sofia', 'Lindgren', 'sofia.lindgren@example.com', '+46 70 100 203', 'Sweden', 'Stockholm', 'small_business', TRUE, '2025-10-08 13:10:00+00'),
    (4, 'Jonas', 'Eriksson', 'jonas.eriksson@example.com', '+46 70 100 204', 'Sweden', 'Malmo', 'retail', TRUE, '2025-10-11 16:40:00+00'),
    (5, 'Emma', 'Schmidt', 'emma.schmidt@example.com', '+49 151 100 205', 'Germany', 'Berlin', 'retail', TRUE, '2025-10-14 10:00:00+00'),
    (6, 'Lucas', 'Meyer', 'lucas.meyer@example.com', '+49 151 100 206', 'Germany', 'Hamburg', 'small_business', FALSE, '2025-10-18 12:30:00+00'),
    (7, 'Claire', 'Dubois', 'claire.dubois@example.com', '+33 6 100 207', 'France', 'Lyon', 'retail', TRUE, '2025-10-21 15:45:00+00'),
    (8, 'Nina', 'Berg', 'nina.berg@example.com', '+47 90 100 208', 'Norway', 'Oslo', 'retail', FALSE, '2025-10-25 08:25:00+00'),
    (9, 'Petr', 'Novak', 'petr.novak@example.com', '+420 601 100 209', 'Czech Republic', 'Prague', 'retail', TRUE, '2025-11-01 09:50:00+00'),
    (10, 'Laura', 'Rossi', 'laura.rossi@example.com', '+39 320 100 210', 'Italy', 'Milan', 'retail', TRUE, '2025-11-04 14:20:00+00'),
    (11, 'Miguel', 'Santos', 'miguel.santos@example.com', '+34 600 100 211', 'Spain', 'Valencia', 'wholesale', TRUE, '2025-11-07 17:05:00+00'),
    (12, 'Hanna', 'Virtanen', 'hanna.virtanen@example.com', '+358 40 100 212', 'Finland', 'Helsinki', 'small_business', TRUE, '2025-11-10 10:35:00+00'),
    (13, 'Tom', 'Baker', 'tom.baker@example.com', '+44 7700 100213', 'United Kingdom', 'Bristol', 'retail', FALSE, '2025-11-13 11:10:00+00'),
    (14, 'Olivia', 'Green', 'olivia.green@example.com', '+353 85 100 214', 'Ireland', 'Dublin', 'retail', TRUE, '2025-11-16 13:55:00+00'),
    (15, 'Katarzyna', 'Wisniewska', 'katarzyna.wisniewska@example.com', '+48 503 100 215', 'Poland', 'Gdansk', 'small_business', TRUE, '2025-11-20 09:05:00+00');

-- ------------------------------------------------------------
-- 3. Inventory
-- ------------------------------------------------------------

INSERT INTO inventory (
    inventory_id,
    product_id,
    quantity_on_hand,
    reorder_level,
    warehouse_location,
    updated_at
)
VALUES
    (1, 1, 120, 25, 'main_warehouse', '2026-01-15 08:00:00+00'),
    (2, 2, 58, 20, 'main_warehouse', '2026-01-15 08:00:00+00'),
    (3, 3, 210, 40, 'main_warehouse', '2026-01-15 08:00:00+00'),
    (4, 4, 37, 15, 'main_warehouse', '2026-01-15 08:00:00+00'),
    (5, 5, 22, 25, 'main_warehouse', '2026-01-15 08:00:00+00'),
    (6, 6, 83, 20, 'main_warehouse', '2026-01-15 08:00:00+00'),
    (7, 7, 18, 10, 'main_warehouse', '2026-01-15 08:00:00+00'),
    (8, 8, 41, 15, 'main_warehouse', '2026-01-15 08:00:00+00'),
    (9, 9, 155, 30, 'main_warehouse', '2026-01-15 08:00:00+00'),
    (10, 10, 64, 20, 'main_warehouse', '2026-01-15 08:00:00+00'),
    (11, 11, 29, 20, 'main_warehouse', '2026-01-15 08:00:00+00'),
    (12, 12, 46, 25, 'main_warehouse', '2026-01-15 08:00:00+00');

-- ------------------------------------------------------------
-- 4. Orders
-- ------------------------------------------------------------

INSERT INTO orders (
    order_id,
    customer_id,
    order_date,
    order_status,
    sales_channel,
    shipping_country,
    shipping_city,
    total_amount
)
VALUES
    (1, 1, '2026-01-03 10:15:00+00', 'delivered', 'online_store', 'Poland', 'Krakow', 0),
    (2, 2, '2026-01-04 12:40:00+00', 'delivered', 'online_store', 'Poland', 'Warsaw', 0),
    (3, 3, '2026-01-05 09:30:00+00', 'shipped', 'manual_invoice', 'Sweden', 'Stockholm', 0),
    (4, 4, '2026-01-06 16:20:00+00', 'delivered', 'marketplace', 'Sweden', 'Malmo', 0),
    (5, 5, '2026-01-07 14:10:00+00', 'delivered', 'online_store', 'Germany', 'Berlin', 0),
    (6, 6, '2026-01-08 11:45:00+00', 'paid', 'manual_invoice', 'Germany', 'Hamburg', 0),
    (7, 7, '2026-01-09 18:05:00+00', 'delivered', 'online_store', 'France', 'Lyon', 0),
    (8, 8, '2026-01-10 08:50:00+00', 'cancelled', 'marketplace', 'Norway', 'Oslo', 0),
    (9, 9, '2026-01-11 13:35:00+00', 'delivered', 'online_store', 'Czech Republic', 'Prague', 0),
    (10, 10, '2026-01-12 15:25:00+00', 'delivered', 'online_store', 'Italy', 'Milan', 0),
    (11, 11, '2026-01-13 10:05:00+00', 'shipped', 'manual_invoice', 'Spain', 'Valencia', 0),
    (12, 12, '2026-01-14 17:15:00+00', 'paid', 'manual_invoice', 'Finland', 'Helsinki', 0),
    (13, 13, '2026-01-15 12:55:00+00', 'delivered', 'online_store', 'United Kingdom', 'Bristol', 0),
    (14, 14, '2026-01-16 09:40:00+00', 'delivered', 'marketplace', 'Ireland', 'Dublin', 0),
    (15, 15, '2026-01-17 11:20:00+00', 'paid', 'manual_invoice', 'Poland', 'Gdansk', 0),
    (16, 1, '2026-01-18 14:45:00+00', 'delivered', 'online_store', 'Poland', 'Krakow', 0),
    (17, 3, '2026-01-19 10:30:00+00', 'shipped', 'manual_invoice', 'Sweden', 'Stockholm', 0),
    (18, 5, '2026-01-20 16:10:00+00', 'delivered', 'online_store', 'Germany', 'Berlin', 0),
    (19, 7, '2026-01-21 13:00:00+00', 'refunded', 'online_store', 'France', 'Lyon', 0),
    (20, 11, '2026-01-22 09:15:00+00', 'paid', 'manual_invoice', 'Spain', 'Valencia', 0),
    (21, 12, '2026-01-23 18:25:00+00', 'shipped', 'online_store', 'Finland', 'Helsinki', 0),
    (22, 15, '2026-01-24 11:35:00+00', 'delivered', 'online_store', 'Poland', 'Gdansk', 0),
    (23, 9, '2026-01-25 15:55:00+00', 'pending', 'marketplace', 'Czech Republic', 'Prague', 0),
    (24, 2, '2026-01-26 10:10:00+00', 'paid', 'online_store', 'Poland', 'Warsaw', 0);

-- ------------------------------------------------------------
-- 5. Order Items
-- ------------------------------------------------------------
-- line_total is generated automatically by the database.

INSERT INTO order_items (
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    discount_amount
)
VALUES
    (1, 1, 1, 2, 8.99, 0),
    (2, 1, 3, 3, 6.75, 0),

    (3, 2, 5, 1, 18.90, 0),
    (4, 2, 9, 2, 5.99, 0),

    (5, 3, 2, 5, 14.50, 5.00),
    (6, 3, 6, 4, 12.25, 0),
    (7, 3, 10, 3, 9.75, 0),

    (8, 4, 4, 1, 11.99, 0),
    (9, 4, 11, 2, 13.40, 0),

    (10, 5, 7, 1, 24.99, 0),
    (11, 5, 8, 1, 19.99, 2.00),

    (12, 6, 12, 6, 16.80, 8.00),
    (13, 6, 3, 10, 6.75, 0),

    (14, 7, 1, 1, 8.99, 0),
    (15, 7, 2, 1, 14.50, 0),
    (16, 7, 9, 1, 5.99, 0),

    (17, 8, 5, 1, 18.90, 0),

    (18, 9, 10, 2, 9.75, 0),
    (19, 9, 3, 4, 6.75, 0),

    (20, 10, 6, 2, 12.25, 0),
    (21, 10, 11, 1, 13.40, 0),

    (22, 11, 7, 4, 24.99, 10.00),
    (23, 11, 8, 4, 19.99, 5.00),
    (24, 11, 12, 5, 16.80, 0),

    (25, 12, 2, 3, 14.50, 0),
    (26, 12, 4, 2, 11.99, 0),

    (27, 13, 1, 1, 8.99, 0),
    (28, 13, 9, 3, 5.99, 0),

    (29, 14, 5, 2, 18.90, 0),
    (30, 14, 10, 1, 9.75, 0),

    (31, 15, 3, 8, 6.75, 0),
    (32, 15, 11, 4, 13.40, 4.00),

    (33, 16, 8, 2, 19.99, 0),
    (34, 16, 12, 1, 16.80, 0),

    (35, 17, 5, 6, 18.90, 12.00),
    (36, 17, 6, 6, 12.25, 0),

    (37, 18, 4, 2, 11.99, 0),
    (38, 18, 10, 2, 9.75, 0),
    (39, 18, 3, 2, 6.75, 0),

    (40, 19, 7, 1, 24.99, 0),

    (41, 20, 1, 10, 8.99, 5.00),
    (42, 20, 2, 8, 14.50, 10.00),
    (43, 20, 9, 12, 5.99, 0),

    (44, 21, 12, 3, 16.80, 0),
    (45, 21, 11, 2, 13.40, 0),

    (46, 22, 5, 1, 18.90, 0),
    (47, 22, 8, 1, 19.99, 0),
    (48, 22, 6, 1, 12.25, 0),

    (49, 23, 4, 1, 11.99, 0),
    (50, 23, 3, 2, 6.75, 0),

    (51, 24, 2, 2, 14.50, 0),
    (52, 24, 10, 1, 9.75, 0);

-- ------------------------------------------------------------
-- Update order totals from order_items
-- ------------------------------------------------------------
-- This keeps totals accurate and avoids manual calculation mistakes.

UPDATE orders o
SET total_amount = totals.order_total
FROM (
    SELECT
        order_id,
        SUM(line_total) AS order_total
    FROM order_items
    GROUP BY order_id
) totals
WHERE o.order_id = totals.order_id;

-- ------------------------------------------------------------
-- 6. Customer Feedback
-- ------------------------------------------------------------

INSERT INTO customer_feedback (
    feedback_id,
    customer_id,
    product_id,
    feedback_date,
    feedback_type,
    rating,
    feedback_text,
    sentiment_label
)
VALUES
    (1, 1, 1, '2026-01-05 10:30:00+00', 'review', 5, 'The bamboo toothbrushes feel sturdy and are nicely packaged. I would buy them again.', 'positive'),
    (2, 2, 5, '2026-01-07 09:20:00+00', 'review', 4, 'The detergent sheets are easy to store and work well for normal laundry.', 'positive'),
    (3, 3, 2, '2026-01-08 14:10:00+00', 'support_ticket', NULL, 'Can I order beeswax wraps in larger quantities for a small shop?', 'neutral'),
    (4, 4, 4, '2026-01-09 16:45:00+00', 'complaint', 2, 'The spray bottle arrived with a loose nozzle and leaked during first use.', 'negative'),
    (5, 5, 7, '2026-01-10 11:50:00+00', 'review', 5, 'The lunch box is solid and looks professional. Great for work lunches.', 'positive'),
    (6, 6, 12, '2026-01-11 08:35:00+00', 'product_question', NULL, 'Are the biodegradable trash bags suitable for food waste bins?', 'neutral'),
    (7, 7, 9, '2026-01-12 17:25:00+00', 'review', 4, 'The loofah sponge is good quality, but I wish it came with a hanging string.', 'positive'),
    (8, 8, 5, '2026-01-13 13:40:00+00', 'complaint', 1, 'I cancelled the order because the delivery estimate was too long.', 'negative'),
    (9, 9, 10, '2026-01-14 15:00:00+00', 'review', 5, 'The wooden dish brush feels durable and cleans pans very well.', 'positive'),
    (10, 10, 6, '2026-01-15 10:05:00+00', 'review', 4, 'The cotton bags are useful for groceries and easy to wash.', 'positive'),
    (11, 11, 8, '2026-01-16 12:30:00+00', 'support_ticket', NULL, 'Please confirm whether the silicone bags are freezer safe.', 'neutral'),
    (12, 12, 4, '2026-01-17 09:45:00+00', 'review', 3, 'The glass bottle looks nice, but it feels heavier than expected.', 'neutral'),
    (13, 13, 9, '2026-01-18 18:10:00+00', 'review', 5, 'Simple, natural, and exactly what I expected.', 'positive'),
    (14, 14, 5, '2026-01-19 11:15:00+00', 'review', 4, 'Good product. I would like a fragrance-free version as well.', 'positive'),
    (15, 15, 11, '2026-01-20 14:55:00+00', 'complaint', 2, 'The recycled paper towels were thinner than expected for business use.', 'negative'),
    (16, 1, 8, '2026-01-21 16:35:00+00', 'review', 5, 'The reusable silicone bags are now part of my weekly meal prep routine.', 'positive');

-- ------------------------------------------------------------
-- 7. Competitor Prices
-- ------------------------------------------------------------

INSERT INTO competitor_prices (
    competitor_price_id,
    product_id,
    competitor_name,
    competitor_product_url,
    competitor_price,
    checked_at
)
VALUES
    (1, 1, 'EcoMarket Online', 'https://example.com/ecomarket/bamboo-toothbrush-set', 9.49, '2026-01-20 08:00:00+00'),
    (2, 1, 'GreenCart', 'https://example.com/greencart/bamboo-toothbrush-set', 8.79, '2026-01-20 08:05:00+00'),
    (3, 2, 'EcoMarket Online', 'https://example.com/ecomarket/beeswax-wraps', 15.25, '2026-01-20 08:10:00+00'),
    (4, 2, 'Sustainable Home Store', 'https://example.com/sustainablehome/beeswax-wraps', 13.99, '2026-01-20 08:15:00+00'),
    (5, 3, 'GreenCart', 'https://example.com/greencart/compostable-sponges', 6.50, '2026-01-20 08:20:00+00'),
    (6, 4, 'EcoMarket Online', 'https://example.com/ecomarket/glass-spray-bottle', 12.49, '2026-01-20 08:25:00+00'),
    (7, 5, 'Sustainable Home Store', 'https://example.com/sustainablehome/laundry-sheets', 19.90, '2026-01-20 08:30:00+00'),
    (8, 5, 'GreenCart', 'https://example.com/greencart/laundry-sheets', 17.95, '2026-01-20 08:35:00+00'),
    (9, 6, 'EcoMarket Online', 'https://example.com/ecomarket/cotton-produce-bags', 12.99, '2026-01-20 08:40:00+00'),
    (10, 7, 'Sustainable Home Store', 'https://example.com/sustainablehome/stainless-lunch-box', 26.50, '2026-01-20 08:45:00+00'),
    (11, 8, 'GreenCart', 'https://example.com/greencart/silicone-food-bags', 18.99, '2026-01-20 08:50:00+00'),
    (12, 8, 'EcoMarket Online', 'https://example.com/ecomarket/silicone-food-bags', 21.25, '2026-01-20 08:55:00+00'),
    (13, 9, 'Sustainable Home Store', 'https://example.com/sustainablehome/loofah-sponge', 6.25, '2026-01-20 09:00:00+00'),
    (14, 10, 'GreenCart', 'https://example.com/greencart/wooden-dish-brush', 9.50, '2026-01-20 09:05:00+00'),
    (15, 11, 'EcoMarket Online', 'https://example.com/ecomarket/recycled-paper-towels', 14.20, '2026-01-20 09:10:00+00'),
    (16, 11, 'GreenCart', 'https://example.com/greencart/recycled-paper-towels', 12.95, '2026-01-20 09:15:00+00'),
    (17, 12, 'Sustainable Home Store', 'https://example.com/sustainablehome/biodegradable-trash-bags', 17.30, '2026-01-20 09:20:00+00'),
    (18, 12, 'EcoMarket Online', 'https://example.com/ecomarket/biodegradable-trash-bags', 16.40, '2026-01-20 09:25:00+00');

-- ------------------------------------------------------------
-- Reset sequences after explicit IDs
-- ------------------------------------------------------------

SELECT setval('products_product_id_seq', (SELECT MAX(product_id) FROM products));
SELECT setval('customers_customer_id_seq', (SELECT MAX(customer_id) FROM customers));
SELECT setval('orders_order_id_seq', (SELECT MAX(order_id) FROM orders));
SELECT setval('order_items_order_item_id_seq', (SELECT MAX(order_item_id) FROM order_items));
SELECT setval('inventory_inventory_id_seq', (SELECT MAX(inventory_id) FROM inventory));
SELECT setval('customer_feedback_feedback_id_seq', (SELECT MAX(feedback_id) FROM customer_feedback));
SELECT setval('competitor_prices_competitor_price_id_seq', (SELECT MAX(competitor_price_id) FROM competitor_prices));

COMMIT;
