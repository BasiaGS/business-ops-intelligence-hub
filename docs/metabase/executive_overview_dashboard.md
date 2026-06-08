# Executive Overview Dashboard

## Purpose

The **Executive Overview** dashboard is the first Metabase dashboard created for the Business Ops Intelligence Hub project.

It provides a high-level view of the EcoHome Supplies business by showing revenue performance, order volume, customer feedback, product performance, sales channel performance, and inventory alerts.

The dashboard is designed for a business stakeholder who wants a quick operational summary without needing to query the database directly.

---

## Dashboard Tool

The dashboard was created in:

```text
Metabase
```

Metabase is used as the business intelligence layer for the project. It connects to the PostgreSQL database running inside the Docker Compose stack.

Connection target:

```text
PostgreSQL database: business_ops
Docker service/container: business_ops_postgres
Metabase container: business_ops_metabase
```

Inside Docker, Metabase connects to PostgreSQL through the container/service name:

```text
business_ops_postgres:5432
```

This is used instead of `localhost` because Metabase runs inside its own container.

---

## Dashboard Name

```text
Executive Overview
```

Location in Metabase:

```text
Our analytics
```

---

## Data Source

The dashboard uses SQL analytics views created in:

```text
db/init/03_create_analytics_views.sql
```

These views prepare dashboard-ready business summaries from the raw relational tables.

Relevant source tables include:

```text
customers
products
orders
order_items
inventory
customer_feedback
competitor_prices
```

---

## Dashboard Cards

### 1. Total Revenue

**Purpose:** Shows total business revenue across the available sample order data.

**Metabase visualization:**

```text
Number
```

**Source view:**

```text
vw_daily_revenue
```

**Metric:**

```text
Sum of Gross Revenue
```

---

### 2. Total Orders

**Purpose:** Shows the total number of orders in the sample dataset.

**Metabase visualization:**

```text
Number
```

**Source view:**

```text
vw_daily_revenue
```

**Metric:**

```text
Sum of Order Count
```

---

### 3. Average Feedback Rating

**Purpose:** Gives a quick customer satisfaction indicator based on feedback ratings.

**Metabase visualization:**

```text
Number
```

**Source view:**

```text
vw_feedback_sentiment_summary
```

**Metric:**

```text
Average Feedback Rating
```

---

### 4. Revenue Over Time

**Purpose:** Shows daily revenue trends over time.

**Metabase visualization:**

```text
Line chart
```

**Source view:**

```text
vw_daily_revenue
```

**X-axis:**

```text
Order Day
```

**Y-axis:**

```text
Sum of Gross Revenue
```

---

### 5. Revenue by Sales Channel

**Purpose:** Compares revenue contribution by sales channel.

**Metabase visualization:**

```text
Bar chart
```

**Source view:**

```text
vw_sales_channel_summary
```

**Dimension:**

```text
Sales Channel
```

**Metric:**

```text
Sum of Gross Revenue
```

---

### 6. Top 5 Products by Revenue

**Purpose:** Identifies the strongest-performing products by revenue.

**Metabase visualization:**

```text
Bar chart
```

**Source view:**

```text
vw_product_sales_summary
```

**Dimension:**

```text
Product Name
```

**Metric:**

```text
Sum of Net Revenue
```

**Sort:**

```text
Net Revenue descending
```

**Limit:**

```text
5 products
```

---

### 7. Inventory Reorder Alerts

**Purpose:** Highlights products that need operational attention because their stock level is at or below the reorder threshold.

**Metabase visualization:**

```text
Table
```

**Source view:**

```text
vw_inventory_reorder_alerts
```

**Filter:**

```text
Stock Status is not healthy
```

**Displayed columns:**

```text
Product Name
Category
Quantity On Hand
Reorder Level
Reorder Needed
Stock Status
Updated At
```

---

## Dashboard Layout

The dashboard uses an executive-style layout:

```text
[ Total Revenue ] [ Total Orders ] [ Average Feedback Rating ]

[ Revenue Over Time                                      ]

[ Revenue by Sales Channel ] [ Top 5 Products by Revenue ]

[ Inventory Reorder Alerts                               ]
```

The top row contains headline KPIs.

The middle section shows revenue movement over time.

The lower section shows business performance breakdowns.

The final section shows inventory issues that may require action.

---

## Screenshots

### KPI and Revenue Trend Section

![Executive Overview Dashboard - KPIs and Revenue Trend](../screenshots/metabase_executive_overview_dashboard_1.png)

### Revenue Breakdown and Inventory Alerts Section

![Executive Overview Dashboard - Revenue Breakdown and Inventory Alerts](../screenshots/metabase_executive_overview_dashboard_2.png)


## Current Dashboard Values

At the time of creation, the dashboard showed:

```text
Total Revenue: 1,809
Total Orders: 22
Average Feedback Rating: 4.15
Inventory Reorder Alerts: 1 product requiring reorder
```

These values come from the local sample dataset seeded into PostgreSQL.

---

## Why This Dashboard Matters

This dashboard demonstrates the business intelligence layer of the project.

It shows that the project can:

```text
1. Store structured business data in PostgreSQL
2. Transform raw relational data into analytics-ready SQL views
3. Connect Metabase to PostgreSQL through Docker networking
4. Build stakeholder-friendly dashboards from SQL views
5. Surface both performance metrics and operational alerts
```

The dashboard turns the database layer into a business-facing analytics product.

---

## Notes

The dashboard currently uses **Gross Revenue** for the main revenue KPI and daily revenue trend because `vw_daily_revenue` exposes `gross_revenue`.

The product performance chart uses **Net Revenue** because `vw_product_sales_summary` exposes `net_revenue`.

A future improvement could standardize revenue naming across all analytics views by exposing both:

```text
gross_revenue
net_revenue
discount_amount
```

This would make revenue definitions more consistent across all Metabase dashboards.

