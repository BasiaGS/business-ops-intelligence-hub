# Inventory Update Workflow Test Commands

## Purpose

This document provides local test commands for the inventory update webhook workflow.

The tests cover the three main workflow execution paths:

```text
1. Authorized and valid payload → successful PostgreSQL inventory update
2. Unauthorized request → authorization error
3. Authorized but invalid payload → validation error
```

These tests are intended for local Docker Compose portfolio review and workflow demonstration.

---

## Prerequisites

Before running these tests:

```text
1. Start the Docker stack.
2. Open n8n at http://localhost:5678.
3. Open the inventory update workflow.
4. Click "Execute workflow" or listen for a test event.
5. Use the /webhook-test/... URL while testing from the n8n editor.
```
---

## Webhook Path

> Use /webhook-test/... while the workflow is open and listening for a test event in n8n.

> Use /webhook/... only after the workflow is active/published.


Test webhook path:

```text
http://localhost:5678/webhook-test/inventory-update
```

Production webhook path, used only after the workflow is active/published:

```text
http://localhost:5678/webhook/inventory-update
```

---

## Webhook Secret

The workflow expects the request header:

```text
x-webhook-secret
```

For public documentation, do not hardcode a real local secret.

Make sure that you provided your own webhook secret in your local `.env` file as `WEBHOOK_SECRET`:

```bash
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


## Test 1 — Success Path

Use a valid webhook secret and valid inventory update payload.

```bash
curl -i -X POST "http://localhost:5678/webhook-test/inventory-update" \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: ${WEBHOOK_SECRET}" \
  -d '{
    "product_id": 5,
    "quantity_on_hand": 42,
    "reorder_level": 20,
    "update_reason": "supplier restock",
    "updated_at": "2026-06-08T15:00:00+02:00"
  }'
```

Expected workflow path:

```text
Webhook
→ Code - Check Secret
→ IF - Is Authorized? = true
→ Code - Validate and Clean Inventory Update
→ IF - Is Payload Valid? = true
→ Update Inventory in Postgres
→ Insert Success Log
→ Respond Success
```

Expected HTTP result:

```text
HTTP/1.1 200 OK
Inventory updated in PostgreSQL
```

Expected log result:

```text
execution_status = success
auth_status = authorized
payload_status = success
response_status_code = 200
event_source = inventory-update-webhook
```

---

## Test 2 — Unauthorized Path

Use an incorrect webhook secret.

```bash
curl -i -X POST "http://localhost:5678/webhook-test/inventory-update" \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: wrong-secret" \
  -d '{
    "product_id": 5,
    "quantity_on_hand": 42,
    "reorder_level": 20,
    "update_reason": "supplier restock",
    "updated_at": "2026-06-08T15:00:00+02:00"
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
event_source = inventory-update-webhook
```

---

## Test 3 — Validation Error Path

Use a payload with the correct field names but one invalid value.

This test passes authorization first, then fails payload validation because `quantity_on_hand` is negative.

```bash
curl -i -X POST "http://localhost:5678/webhook-test/inventory-update" \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: ${WEBHOOK_SECRET}" \
  -d '{
    "product_id": 5,
    "quantity_on_hand": -10,
    "reorder_level": 20,
    "update_reason": "invalid stock test",
    "updated_at": "2026-06-08T15:00:00+02:00"
  }'
```

Expected workflow path:

```text
Webhook
→ Code - Check Secret
→ IF - Is Authorized? = true
→ Code - Validate and Clean Inventory Update
→ IF - Is Payload Valid? = false
→ Insert Validation Error Log
→ Respond Validation Error
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
event_source = inventory-update-webhook
```

---

## PostgreSQL Verification

After testing, connect to PostgreSQL:

```bash
docker exec -it business_ops_postgres psql -U business_ops_admin -d business_ops
```

Check the updated inventory row:

```sql
SELECT
    product_id,
    quantity_on_hand,
    reorder_level,
    warehouse_location,
    updated_at
FROM inventory
WHERE product_id = 5;
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

The inventory update workflow should log:

```text
workflow_name = inventory_update_webhook
event_source = inventory-update-webhook
```

The `event_source` field is the preferred dashboard grouping field for workflow comparison.
