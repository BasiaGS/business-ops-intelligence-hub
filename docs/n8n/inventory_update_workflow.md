# Inventory Update Webhook Workflow

## Purpose

This document describes Step 18 of the Business Ops Intelligence Hub project.

In earlier steps, the project added a customer feedback webhook workflow that receives external JSON, checks a shared secret, validates the payload, writes to PostgreSQL, logs workflow execution results, and returns clear HTTP responses.

Step 18 adds a second business automation:

```text
Inventory Update Workflow
```

This workflow proves that the automation layer is not limited to customer feedback ingestion. It can also update existing operational business data.

The workflow receives an inventory update payload through an n8n webhook, validates it, updates the PostgreSQL `inventory` table, logs the execution result, and returns a clear HTTP response.

---

## Workflow Name

```text
Update Inventory from Webhook
```

---

## Webhook Paths

Test webhook path:

```text
/webhook-test/inventory-update
```

Production webhook path:

```text
/webhook/inventory-update
```

Important n8n distinction:

```text
/webhook-test/...  = used while testing inside n8n
/webhook/...       = production URL, works when the workflow is active/published
```

---

## Security Pattern

The workflow uses the same security pattern as the customer feedback webhook.

Required HTTP header:

```text
x-webhook-secret
```

The expected secret is read from the n8n container environment:

```javascript
const expectedSecret = $env.WEBHOOK_SECRET;
```

The real local secret value is not hardcoded in the workflow export.

---

## Expected Payload

Example valid payload:

```json
{
  "product_id": 5,
  "quantity_on_hand": 43,
  "reorder_level": 20,
  "update_reason": "production webhook test",
  "updated_at": "2026-06-08T16:00:00+02:00"
}
```

Required fields:

```text
product_id
quantity_on_hand
```

Optional fields:

```text
reorder_level
update_reason
updated_at
```

---

## Validation Rules

The validation Code node checks:

```text
product_id must be a positive number
quantity_on_hand must be a number greater than or equal to 0
reorder_level must be a number greater than or equal to 0 when provided
update_reason is trimmed when provided
updated_at defaults to the current timestamp when not provided
```

Invalid payloads are rejected before PostgreSQL is updated.

---

## Database Target

The workflow updates:

```text
public.inventory
```

Updated columns:

```text
quantity_on_hand
reorder_level
updated_at
```

Matching column:

```text
product_id
```

The workflow does not update:

```text
inventory_id
warehouse_location
```

---

## Workflow Structure

```text
Webhook - Inventory Update
→ Code - Check Secret
→ IF - Is Authorized?
    ├── false → Insert Unauthorized Log → Respond Unauthorized
    └── true  → Code - Validate and Clean Inventory Update
                → IF - Is Payload Valid?
                    ├── true  → Update Inventory in Postgres
                    │           → Insert Success Log
                    │           → Respond Success
                    └── false → Insert Validation Error Log
                                → Respond Validation Error
```

---

## Execution Paths

The workflow supports three important paths.

### Unauthorized Request

Cause:

```text
Missing or incorrect x-webhook-secret header
```

Result:

```text
HTTP 401
workflow_execution_logs row inserted
inventory table not updated
```

Response:

```json
{
  "auth_status": "unauthorized",
  "status": "error",
  "message": "Unauthorized request"
}
```

### Authorized Invalid Payload

Cause:

```text
Payload passes authorization but fails validation
```

Example:

```json
{
  "product_id": 5,
  "quantity_on_hand": -10,
  "reorder_level": 20,
  "update_reason": "invalid stock test",
  "updated_at": "2026-06-08T15:00:00+02:00"
}
```

Result:

```text
HTTP 400
workflow_execution_logs row inserted
inventory table not updated
```

Response:

```json
{
  "status": "error",
  "message": "Invalid payload",
  "errors": [
    "quantity_on_hand is required and must be a number greater than or equal to 0"
  ]
}
```

### Authorized Valid Payload

Cause:

```text
Correct secret header and valid inventory payload
```

Result:

```text
HTTP 200
inventory table updated
workflow_execution_logs row inserted
```

Response:

```json
{
  "status": "success",
  "message": "Inventory updated in PostgreSQL"
}
```

---

## Workflow Logging

The workflow reuses the existing PostgreSQL table:

```text
workflow_execution_logs
```

Inventory workflow rows use:

```text
workflow_name: inventory_update_webhook
event_source: inventory-update-webhook
```

The workflow logs:

```text
success
unauthorized
validation_error
```

For inventory workflow logs, the `product_id` field is used when the payload is authorized and includes a product ID.

Customer-feedback-specific fields are left empty:

```text
customer_id
feedback_type
rating
```

This keeps the existing log table reusable without changing the schema in Step 18.

---

## Test Results

### Test 1 — Authorized Valid Production Request

Command:

```bash
curl -i -X POST "http://localhost:5678/webhook/inventory-update" \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: local-dev-secret" \
  -d '{
    "product_id": 5,
    "quantity_on_hand": 43,
    "reorder_level": 20,
    "update_reason": "production webhook test",
    "updated_at": "2026-06-08T16:00:00+02:00"
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
  "message": "Inventory updated in PostgreSQL"
}
```

### Test 2 — Unauthorized Request

Command:

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

Result:

```text
HTTP/1.1 401 Unauthorized
```

Response:

```json
{
  "auth_status": "unauthorized",
  "status": "error",
  "message": "Unauthorized request"
}
```

### Test 3 — Authorized Invalid Payload

Command:

```bash
curl -i -X POST "http://localhost:5678/webhook-test/inventory-update" \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: local-dev-secret" \
  -d '{
    "product_id": 5,
    "quantity_on_hand": -10,
    "reorder_level": 20,
    "update_reason": "invalid stock test",
    "updated_at": "2026-06-08T15:00:00+02:00"
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
    "quantity_on_hand is required and must be a number greater than or equal to 0"
  ]
}
```

---

## PostgreSQL Verification

Inventory update verification query:

```sql
SELECT
    inventory_id,
    product_id,
    quantity_on_hand,
    reorder_level,
    warehouse_location,
    updated_at
FROM inventory
WHERE product_id = 5;
```

Verified result:

```text
inventory_id:       5
product_id:         5
quantity_on_hand:   43
reorder_level:      20
warehouse_location: main_warehouse
updated_at:         2026-06-08 14:00:00+00
```

Workflow log verification query:

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

Verified recent inventory workflow rows:

```text
inventory_update_webhook | inventory-update-webhook | validation_error | authorized   | error   | 400 | product_id 5
inventory_update_webhook | inventory-update-webhook | unauthorized     | unauthorized |         | 401 | product_id empty
inventory_update_webhook | inventory-update-webhook | success          | authorized   | success | 200 | product_id 5
```

---

## Exported Workflow

The workflow was exported and version-controlled here:

```text
n8n/workflows/inventory_update_webhook_workflow.json
```

The exported workflow was checked with:

```bash
bash scripts/check_workflow_secrets.sh
```

Result:

```text
PASS: workflow secret checks completed successfully
```

---

## What This Step Proves

Step 18 proves that the project can support more than one business automation.

The project now has:

```text
Customer feedback automation
Inventory update automation
PostgreSQL workflow logging
Reusable webhook security pattern
Reusable validation and response pattern
Version-controlled n8n workflow exports
```

This strengthens the portfolio story because the system now looks like a small operational automation platform, not a single-purpose webhook demo.

---

## Future Improvements

Possible future improvements:

```text
1. Extend the Metabase workflow observability dashboard to compare multiple workflow types.
2. Add inventory-specific audit columns or a separate inventory update history table.
3. Add alerts for low stock after an inventory update.
4. Add foreign-key existence checks before attempting the update.
5. Return the updated inventory row in the success response.
6. Track n8n execution IDs and execution duration.
```
