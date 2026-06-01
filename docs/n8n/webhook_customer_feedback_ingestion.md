# Webhook Customer Feedback Ingestion Workflow

## Purpose

This workflow is the Step 8 automation for the Business Ops Intelligence Hub project.

It replaces the earlier manual n8n test workflow with a webhook-based ingestion workflow.

The workflow receives customer feedback data from an external HTTP request, validates and cleans the payload, inserts valid records into PostgreSQL, and returns a success or validation error response.

This makes the project more realistic because the data now enters the system from outside n8n, similar to how data could come from a website form, app, API, or external business tool.

---

## Workflow Name

```text
Webhook Customer Feedback Ingestion

```
---

## What Is a Webhook?

A webhook is a URL that waits for another system to send data to it.

In this project, the webhook receives customer feedback JSON.

Example:

```text
External system
→ sends JSON to n8n webhook URL
→ n8n workflow starts automatically
```

During testing, the webhook URL used was:

```text
http://localhost:5678/webhook-test/customer-feedback
```

In n8n:

```text
/webhook-test/...  = test URL, works after clicking Execute workflow or Listen for test event
/webhook/...       = production URL, works after activating the workflow
```

---

## Workflow Structure

```text
Webhook
→ Code - Validate and Clean Feedback
→ IF - Is Payload Valid?
    ├── true  → Insert Feedback to Postgres → Respond to Webhook - Success Response
    └── false → Respond with Validation Error to Webhook
```

---

## Node 1 — Webhook

The Webhook node receives incoming customer feedback data.

Settings:

```text
HTTP Method: POST
Path: customer-feedback
Authentication: None
Respond: Using "Respond to Webhook" Node
```

Example test URL:

```text
http://localhost:5678/webhook-test/customer-feedback
```

---

## Example Valid Payload

```json
{
  "customer_id": 3,
  "product_id": 5,
  "feedback_date": "2026-05-30T13:00:00+02:00",
  "feedback_type": "review",
  "rating": 4,
  "feedback_text": "Webhook validation and insert branch works correctly."
}
```

---

## Node 2 — Code: Validate and Clean Feedback

The Code node validates and prepares the incoming JSON before database insertion.

It performs these checks:

```text
customer_id is required and must be a positive number
product_id is required and must be a positive number
feedback_type must be one of: review, support_ticket, complaint, product_question
rating must be a number between 1 and 5
feedback_text is required and cannot be empty
feedback_date is optional; if missing, current date/time is used
```

It also derives `sentiment_label` from `rating`:

```text
rating >= 4 → positive
rating = 3  → neutral
rating <= 2 → negative
```

Successful cleaned output includes:

```text
customer_id
product_id
feedback_date
feedback_type
rating
feedback_text
sentiment_label
```

---

## Node 3 — IF: Is Payload Valid?

The IF node decides whether the workflow should insert the record into PostgreSQL.

Condition:

```text
Value 1: {{ $json.status }}
Operation: equals
Value 2: success
```

Logic:

```text
If status = success:
    continue to PostgreSQL insert

If status = error:
    skip PostgreSQL and return validation errors
```

This protects the database from invalid incoming data.

---

## Node 4A — Insert Feedback to Postgres

This node runs only for valid payloads.

Target table:

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

PostgreSQL generates those automatically.

The workflow uses the existing n8n PostgreSQL credential.

Connection details:

```text
Host: postgres
Database: business_ops
User: business_ops_admin
Port: 5432
SSL: Disabled
SSH Tunnel: Off
```

The host is `postgres` because n8n and PostgreSQL run inside the same Docker Compose network.

---

## Node 4B — Respond with Validation Error to Webhook

This node runs only for invalid payloads.

Settings:

```text
Respond With: JSON
Response Code: 400
Response Body: {{ $json }}
```

Example invalid response:

```json
{
  "status": "error",
  "message": "Invalid payload",
  "errors": [
    "feedback_type must be one of: review, support_ticket, complaint, product_question",
    "rating must be a number between 1 and 5",
    "feedback_text is required and cannot be empty"
  ]
}
```

This confirms that invalid records are rejected before reaching PostgreSQL.

---

## Node 5 — Respond to Webhook: Success Response

This node runs after a successful PostgreSQL insert.

Settings:

```text
Respond With: JSON
Response Code: 200
```

Response body:

```json
{
  "status": "success",
  "message": "Customer feedback inserted into PostgreSQL"
}
```

---

## Valid Payload Test

Command:

```bash
curl -i -X POST "http://localhost:5678/webhook-test/customer-feedback" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": 3,
    "product_id": 5,
    "feedback_date": "2026-05-30T13:00:00+02:00",
    "feedback_type": "review",
    "rating": 4,
    "feedback_text": "Webhook validation and insert branch works correctly."
  }'
```

Result:

```text
HTTP/1.1 200 OK
```

Response:

```json
{
  "status": "success",
  "message": "Customer feedback inserted into PostgreSQL"
}
```

---

## Invalid Payload Test

Command:

```bash
curl -i -X POST "http://localhost:5678/webhook-test/customer-feedback" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": 3,
    "product_id": 5,
    "feedback_date": "2026-05-30T13:00:00+02:00",
    "feedback_type": "wrong_type",
    "rating": 9,
    "feedback_text": ""
  }'
```

Result:

```text
HTTP/1.1 400 Bad Request
```

Response:

```json
{
  "status": "error",
  "message": "Invalid payload",
  "errors": [
    "feedback_type must be one of: review, support_ticket, complaint, product_question",
    "rating must be a number between 1 and 5",
    "feedback_text is required and cannot be empty"
  ]
}
```

---

## PostgreSQL Verification Query

After a successful valid payload test, the inserted row was verified with:

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

Newest inserted record:

```text
feedback_id:      19
customer_id:      3
product_id:       5
feedback_date:    2026-05-30 11:00:00+00
feedback_type:    review
rating:           4
sentiment_label:  positive
feedback_text:    Webhook validation and insert branch works correctly.
```

---

## Analytics View Verification

The dashboard-facing SQL view can be checked with:

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

This confirms that Metabase can use the updated feedback data through the existing analytics view.

---

## What This Workflow Proves

This workflow proves that:

```text
1. n8n can expose a webhook endpoint
2. external JSON data can be sent into n8n with curl
3. n8n can validate and clean incoming business data
4. invalid records are stopped before PostgreSQL
5. valid records are inserted into the customer_feedback table
6. PostgreSQL constraints and n8n validation work together
7. SQL analytics views reflect newly ingested operational data
8. Metabase can use the updated database state
```

---

## Future Improvements

Possible future improvements:

```text
1. Activate the workflow and use the production webhook URL
2. Add authentication or a secret token to protect the webhook
3. Return the inserted feedback_id in the success response
4. Add duplicate detection
5. Add a workflow execution log table
6. Add better error handling for missing customer_id or product_id foreign keys
7. Connect the webhook to a real form or frontend
8. Add AI-assisted feedback categorization later
```
