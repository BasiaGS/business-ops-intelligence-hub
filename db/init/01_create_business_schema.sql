-- ============================================================
-- EcoHome Supplies - Business Database Schema
-- Project: business-ops-intelligence-hub
-- Database: business_ops
-- ============================================================

-- This schema models a small sustainable home-products e-commerce business.
-- It supports future analytics, workflow automation, dashboards, and AI insights.

-- ------------------------------------------------------------
-- 1. Customers
-- ------------------------------------------------------------
-- Stores people or companies who buy from EcoHome Supplies.
CREATE TABLE IF NOT EXISTS customers (
    customer_id BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(50),
    country VARCHAR(100) NOT NULL,
    city VARCHAR(100),
    customer_segment VARCHAR(50) NOT NULL DEFAULT 'retail',
    marketing_consent BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT customers_segment_check
        CHECK (customer_segment IN ('retail', 'small_business', 'wholesale'))
);

-- ------------------------------------------------------------
-- 2. Products
-- ------------------------------------------------------------
-- Stores the products sold by EcoHome Supplies.
CREATE TABLE IF NOT EXISTS products (
    product_id BIGSERIAL PRIMARY KEY,
    sku VARCHAR(50) NOT NULL UNIQUE,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    supplier_name VARCHAR(255),
    unit_price NUMERIC(10, 2) NOT NULL,
    cost_price NUMERIC(10, 2) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT products_unit_price_check
        CHECK (unit_price >= 0),

    CONSTRAINT products_cost_price_check
        CHECK (cost_price >= 0)
);

-- ------------------------------------------------------------
-- 3. Orders
-- ------------------------------------------------------------
-- Stores one purchase event.
-- One customer can have many orders.
CREATE TABLE IF NOT EXISTS orders (
    order_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    order_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    order_status VARCHAR(50) NOT NULL DEFAULT 'pending',
    sales_channel VARCHAR(50) NOT NULL DEFAULT 'online_store',
    shipping_country VARCHAR(100) NOT NULL,
    shipping_city VARCHAR(100),
    total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE RESTRICT,

    CONSTRAINT orders_status_check
        CHECK (order_status IN ('pending', 'paid', 'shipped', 'delivered', 'cancelled', 'refunded')),

    CONSTRAINT orders_sales_channel_check
        CHECK (sales_channel IN ('online_store', 'marketplace', 'manual_invoice')),

    CONSTRAINT orders_total_amount_check
        CHECK (total_amount >= 0)
);

-- ------------------------------------------------------------
-- 4. Order Items
-- ------------------------------------------------------------
-- Stores the individual products inside each order.
-- One order can contain many order items.
CREATE TABLE IF NOT EXISTS order_items (
    order_item_id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
    discount_amount NUMERIC(10, 2) NOT NULL DEFAULT 0,
    line_total NUMERIC(12, 2) GENERATED ALWAYS AS (
        (quantity * unit_price) - discount_amount
    ) STORED,

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE RESTRICT,

    CONSTRAINT order_items_quantity_check
        CHECK (quantity > 0),

    CONSTRAINT order_items_unit_price_check
        CHECK (unit_price >= 0),

    CONSTRAINT order_items_discount_check
        CHECK (discount_amount >= 0)
);

-- ------------------------------------------------------------
-- 5. Inventory
-- ------------------------------------------------------------
-- Stores stock levels for each product.
CREATE TABLE IF NOT EXISTS inventory (
    inventory_id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL UNIQUE,
    quantity_on_hand INTEGER NOT NULL DEFAULT 0,
    reorder_level INTEGER NOT NULL DEFAULT 10,
    warehouse_location VARCHAR(100) NOT NULL DEFAULT 'main_warehouse',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE,

    CONSTRAINT inventory_quantity_check
        CHECK (quantity_on_hand >= 0),

    CONSTRAINT inventory_reorder_level_check
        CHECK (reorder_level >= 0)
);

-- ------------------------------------------------------------
-- 6. Customer Feedback
-- ------------------------------------------------------------
-- Stores reviews, support comments, complaints, and product feedback.
-- This table will later be useful for AI / semantic search.
CREATE TABLE IF NOT EXISTS customer_feedback (
    feedback_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT,
    product_id BIGINT,
    feedback_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    feedback_type VARCHAR(50) NOT NULL DEFAULT 'review',
    rating INTEGER,
    feedback_text TEXT NOT NULL,
    sentiment_label VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_feedback_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE SET NULL,

    CONSTRAINT fk_feedback_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE SET NULL,

    CONSTRAINT feedback_type_check
        CHECK (feedback_type IN ('review', 'support_ticket', 'complaint', 'product_question')),

    CONSTRAINT feedback_rating_check
        CHECK (rating IS NULL OR rating BETWEEN 1 AND 5),

    CONSTRAINT feedback_sentiment_check
        CHECK (sentiment_label IS NULL OR sentiment_label IN ('positive', 'neutral', 'negative'))
);

-- ------------------------------------------------------------
-- 7. Competitor Prices
-- ------------------------------------------------------------
-- Stores market comparison data for products.
-- This can later support pricing dashboards and automated monitoring.
CREATE TABLE IF NOT EXISTS competitor_prices (
    competitor_price_id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL,
    competitor_name VARCHAR(255) NOT NULL,
    competitor_product_url TEXT,
    competitor_price NUMERIC(10, 2) NOT NULL,
    checked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_competitor_prices_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE,

    CONSTRAINT competitor_price_check
        CHECK (competitor_price >= 0)
);

-- ------------------------------------------------------------
-- Indexes
-- ------------------------------------------------------------
-- Indexes make common searches faster.
-- They are useful for dashboards, queries, and automation workflows.

CREATE INDEX IF NOT EXISTS idx_customers_email
    ON customers(email);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id
    ON orders(customer_id);

CREATE INDEX IF NOT EXISTS idx_orders_order_date
    ON orders(order_date);

CREATE INDEX IF NOT EXISTS idx_orders_order_status
    ON orders(order_status);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id
    ON order_items(order_id);

CREATE INDEX IF NOT EXISTS idx_order_items_product_id
    ON order_items(product_id);

CREATE INDEX IF NOT EXISTS idx_products_category
    ON products(category);

CREATE INDEX IF NOT EXISTS idx_feedback_product_id
    ON customer_feedback(product_id);

CREATE INDEX IF NOT EXISTS idx_feedback_customer_id
    ON customer_feedback(customer_id);

CREATE INDEX IF NOT EXISTS idx_feedback_date
    ON customer_feedback(feedback_date);

CREATE INDEX IF NOT EXISTS idx_competitor_prices_product_id
    ON competitor_prices(product_id);

CREATE INDEX IF NOT EXISTS idx_competitor_prices_checked_at
    ON competitor_prices(checked_at);
