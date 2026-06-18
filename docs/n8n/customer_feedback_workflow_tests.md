# Customer Feedback Workflow Test Commands

## Purpose

This document provides local test commands for the customer feedback webhook workflow.

The tests cover the three main workflow execution paths:

```text
1. Authorized but invalid payload → validation error
2. Unauthorized request → authorization error
3. Authorized and valid payload → successful PostgreSQL insert
```

These tests are intended for local Docker Compose portfolio review and workflow demonstration.

---

## Prerequisites

Before running these tests:

```text
1. Start the Docker stack.
2. Open n8n at http://localhost:5678.
3. Open the customer feedback workflow.
4. Click "Execute workflow" or listen for a test event.
5. Use the /webhook-test/... URL while testing from the n8n editor.
```
---


## Webhook Path

> Use /webhook-test/... while the workflow is open and listening for a test event in n8n.

> Use /webhook/... only after the workflow is active/published.


Test webhook path:

```text
http://localhost:5678/webhook-test/customer-feedback
```

Production webhook path, used only after the workflow is active/published:

```text
http://localhost:5678/webhook/customer-feedback
```

---

## Webhook Secret

The workflow expects the request header:

```text
x-webhook-secret
```

For public documentation, do not hardcode a real local secret.

Make sure that you provided your own webhook secret in your local `.env` file as `WEBHOOK_SECRET`:

```text
WEBHOOK_SECRET="your_local_webhook_secret"
```


**IMPORTANT**
! --> At the start of a testing session, run these commands to check that Webhook Variable is set:

```bash
export WEBHOOK_SECRET="$(grep '^WEBHOOK_SECRET=' .env | cut -d '=' -f2-)"
```

```bash
echo "$WEBHOOK_SECRET"
```

Expected:

```text
your_local_webhook_secret
```

---

## Test 1 — Validation Error Path

Use a payload with the correct field names but one invalid value.

This test passes authorization first, then fails payload validation because `rating` is too high.

```bash
curl -i -X POST "http://localhost:5678/webhook-test/customer-feedback" \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: ${WEBHOOK_SECRET}" \
  -d '{
    "customer_id": 3,
    "product_id": 5,
    "feedback_date": "2026-06-03T13:00:00+02:00",
    "feedback_type": "review",
    "rating": 10,
    "feedback_text": "This should fail validation because rating is too high."
  }'
```

Expected workflow path:

```text
Webhook
→ Code - Check Secret
→ IF - Is Authorized? = true
→ Code - Validate and Clean Feedback
→ IF - Is Payload Valid? = false
→ Insert Validation Error Log
→ Respond with Validation Error to Webhook
```

Expected HTTP result:

```text
HTTP/1.1 400 Bad Request
Invalid payload
```

Expected log result:

```text
execution_status = validation_error
auth_status = authorized
payload_status = error
response_status_code = 400
event_source = customer-feedback-webhook
```

---

## Test 2 — Unauthorized Path

Use an incorrect webhook secret.

```bash
curl -i -X POST "http://localhost:5678/webhook-test/customer-feedback" \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: wrong-secret" \
  -d '{
    "customer_id": 3,
    "product_id": 5,
    "feedback_date": "2026-06-03T13:00:00+02:00",
    "feedback_type": "review",
    "rating": 5,
    "feedback_text": "This should fail authorization."
  }'
```

Expected workflow path:

```text
Webhook
→ Code - Check Secret
→ IF - Is Authorized? = false
→ Insert Unauthorized Log
→ Respond Unauthorized
```

Expected HTTP result:

```text
HTTP/1.1 401 Unauthorized
Unauthorized request
```

Expected log result:

```text
execution_status = unauthorized
auth_status = unauthorized
response_status_code = 401
event_source = customer-feedback-webhook
```

---

## Test 3 — Success Path

Use a valid webhook secret and valid payload.

```bash
curl -i -X POST "http://localhost:5678/webhook-test/customer-feedback" \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: ${WEBHOOK_SECRET}" \
  -d '{
    "customer_id": 3,
    "product_id": 5,
    "feedback_date": "2026-06-03T13:00:00+02:00",
    "feedback_type": "review",
    "rating": 5,
    "feedback_text": "Workflow execution logging works correctly."
  }'
```

Expected workflow path:

```text
Webhook
→ Code - Check Secret
→ IF - Is Authorized? = true
→ Code - Validate and Clean Feedback
→ IF - Is Payload Valid? = true
→ Insert Feedback to Postgres
→ Insert Success Log
→ Respond Success
```

Expected HTTP result:

```text
HTTP/1.1 200 OK
Customer feedback inserted into PostgreSQL
```

Expected log result:

```text
execution_status = success
auth_status = authorized
payload_status = success
response_status_code = 200
event_source = customer-feedback-webhook
```

---

## PostgreSQL Verification

After testing, connect to PostgreSQL:

```bash
docker exec -it business_ops_postgres psql -U business_ops_admin -d business_ops
```

Check the latest customer feedback rows:

```sql
SELECT
    feedback_id,
    customer_id,
    product_id,
    feedback_date,
    feedback_type,
    rating,
    feedback_text,
    created_at
FROM customer_feedback
ORDER BY created_at DESC
LIMIT 10;
```

Check the latest workflow logs:

```sql
SELECT
    log_id,
    created_at,
    workflow_name,
    event_source,
    execution_status,
    auth_status,
    payload_status,
    response_status_code,
    customer_id,
    product_id,
    feedback_type,
    rating,
    error_message
FROM workflow_execution_logs
ORDER BY created_at DESC
LIMIT 10;
```

Exit PostgreSQL:

```sql
\q
```

---

## Expected Workflow Identifiers

The customer feedback workflow should log:

```text
workflow_name = customer_feedback_webhook
event_source = customer-feedback-webhook
```

The `event_source` field is the preferred dashboard grouping field for workflow comparison.
