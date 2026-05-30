# n8n Customer Feedback Workflow

## Purpose

This workflow is the first automation proof for the Business Ops Intelligence Hub project.

It demonstrates that n8n can prepare incoming business data and insert it into the PostgreSQL `business_ops` database.

The workflow uses customer feedback data because it is simpler than order ingestion and connects directly to the existing Metabase feedback dashboard metric.

---

## Workflow Name

```text
Insert Customer Feedback to Postgres

```

## Workflow Structure

```text
Manual Trigger
→ Edit Fields
→ Code
→ Postgres Insert
```

---

## Nodes

### 2. Edit Fields

Creates a sample customer feedback payload.

Test payload used:

```text
customer_id: 3
product_id: 5
feedback_date: 2026-05-30T13:00:00+02:00
feedback_type: review
rating: 5
feedback_text: Great product quality and fast delivery.
```

The selected customer and product were confirmed to exist in PostgreSQL:

```text
customer_id 3 → Sofia Lindgren
product_id 5  → Eco Laundry Detergent Sheets
```

---

### 3. Code

Transforms and cleans the incoming data before database insert.

The Code node:

```text
1. Converts customer_id, product_id, and rating to numbers
2. Trims feedback_text
3. Derives sentiment_label from rating
```

Sentiment logic:

```text
rating >= 4 → positive
rating = 3  → neutral
rating <= 2 → negative
```

JavaScript is used because n8n workflows and expressions are JSON/JavaScript-oriented.

Python remains the main language for heavier data work, notebooks, machine learning, and external scripts.

---

### 4. Postgres Insert

Inserts the cleaned feedback record into:

```text
public.customer_feedback
```

Inserted columns:

```text
customer_id
product_id
feedback_date
feedback_type
rating
feedback_text
sentiment_label
```

Columns not inserted manually:

```text
feedback_id
created_at
```

These are generated automatically by PostgreSQL.

---

## Database Connection

The n8n Postgres credential connects to the project database.

Connection settings:

```text
Host: postgres
Database: business_ops
User: business_ops_admin
Port: 5432
SSL: Disabled
SSH Tunnel: Off
```

The host is `postgres` because n8n and PostgreSQL run inside the same Docker Compose network.

Inside Docker, containers communicate through service names, not through `localhost`.

---

## Verification Query

After executing the workflow, the inserted feedback record was verified with:

```sql
SELECT
    feedback_id,
    customer_id,
    product_id,
    feedback_date,
    feedback_type,
    rating,
    sentiment_label,
    feedback_text
FROM customer_feedback
ORDER BY feedback_id DESC
LIMIT 5;
```

The newest inserted record was:

```text
feedback_id:      17
customer_id:      3
product_id:       5
feedback_date:    2026-05-30 11:00:00+00
feedback_type:    review
rating:           5
sentiment_label:  positive
feedback_text:    Great product quality and fast delivery.
```

The timestamp was inserted as:

```text
2026-05-30T13:00:00+02:00
```

PostgreSQL displayed it as UTC:

```text
2026-05-30 11:00:00+00
```

This is expected behavior.

---

## Analytics View Verification

The workflow result was also verified through the dashboard-facing SQL view:

```sql
SELECT
    product_id,
    product_name,
    feedback_count,
    positive_count,
    neutral_count,
    negative_count,
    average_rating,
    latest_feedback_date
FROM vw_feedback_sentiment_summary
WHERE product_id = 5;
```

Result after workflow execution:

```text
product_id:            5
product_name:          Eco Laundry Detergent Sheets
feedback_count:        4
positive_count:        3
neutral_count:         0
negative_count:        1
average_rating:        3.50
latest_feedback_date:  2026-05-30 11:00:00+00
```

---

## What This Proves

This workflow proves that:

```text
1. n8n can connect to the project PostgreSQL database
2. n8n can prepare and clean incoming business data
3. n8n can insert records into the business_ops database
4. PostgreSQL constraints preserve data quality
5. SQL analytics views reflect new operational data
6. Metabase can use the updated database state through existing views
```

This completes the first n8n automation foundation for the project.

---

## Future Improvements

Possible next improvements:

```text
1. Replace Manual Trigger with a Webhook trigger
2. Accept feedback from an external form or API
3. Add validation before inserting into PostgreSQL
4. Add error handling for invalid customer_id or product_id
5. Add duplicate detection
6. Add a workflow execution log table
7. Extend automation to order ingestion
8. Add AI-assisted feedback categorization later
```
