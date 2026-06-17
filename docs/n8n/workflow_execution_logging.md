# n8n Workflow Execution Logging

## Purpose

This document describes Step 10 of the Business Ops Intelligence Hub project.

In Step 9, the customer feedback webhook was protected with a simple HTTP header security check and activated as a production webhook.

In Step 10, PostgreSQL workflow execution logging was added.

This means every important webhook path now leaves an audit trail in the business database.

The workflow now logs:

- unauthorized requests
- validation errors
- successful customer feedback inserts

This makes the automation layer easier to monitor, debug, and explain.

---

## Why Workflow Logging Was Added

n8n already has an Executions tab, but that execution history lives inside n8n.

For a business intelligence project, it is useful to also store workflow activity in PostgreSQL.

This allows the database to answer questions such as:

- how many webhook requests succeeded
- how many requests were unauthorized
- how many payloads failed validation
- when the latest webhook activity happened
- what kind of error occurred

This is part of workflow observability.

Observability means the system does not only perform work, but also records enough information to understand what happened.

---

## New PostgreSQL Table

A new table was added:

```text
workflow_execution_logs
```text


The SQL file is:

```text
db/init/04_create_workflow_logs.sql
```

The table stores one row for each important webhook execution path.

Important columns include:

```text
log_id
workflow_name
event_source
execution_status
auth_status
payload_status
response_status_code
customer_id
product_id
feedback_type
rating
error_message
created_at
```

The `log_id` column is generated automatically by PostgreSQL.

The `created_at` column is also generated automatically with the current timestamp.

---

## Important Docker Note

The SQL file was saved in:

```text
db/init/04_create_workflow_logs.sql
```

Files inside `db/init` only run automatically when the Postgres Docker volume is first created.

Because the database already existed, the SQL file was also applied manually with:

```bash
docker exec -i business_ops_postgres psql -U business_ops_admin -d business_ops < db/init/04_create_workflow_logs.sql
```

The result was:

```text
CREATE TABLE
CREATE INDEX
CREATE INDEX
CREATE INDEX
```

---

## Updated n8n Workflow Structure

Before Step 10, the workflow was:

```text
Webhook
→ Code - Check Secret
→ IF - Is Authorized?
    ├── false → Respond Unauthorized
    └── true  → Code - Validate and Clean Feedback
                → IF - Is Payload Valid?
                    ├── true  → Insert Feedback to Postgres → Respond Success
                    └── false → Respond Validation Error
```

After Step 10, the workflow became:

```text
Webhook
→ Code - Check Secret
→ IF - Is Authorized?
    ├── false → Insert Unauthorized Log → Respond Unauthorized
    └── true  → Code - Validate and Clean Feedback
                → IF - Is Payload Valid?
                    ├── true  → Insert Feedback to Postgres → Insert Success Log → Respond Success
                    └── false → Insert Validation Error Log → Respond Validation Error
```

---

## New n8n Nodes Added

Three PostgreSQL insert nodes were added:

```text
Insert Unauthorized Log
Insert Validation Error Log
Insert Success Log
```

Each node inserts into:

```text
workflow_execution_logs
```

The existing customer feedback insert node still inserts into:

```text
customer_feedback
```

---

## Workflow Name Standardization

In Step 20, `workflow_name` values were standardized so workflow logs use stable technical identifiers instead of display-style workflow names.

Current `workflow_name` values:

```text
customer_feedback_webhook
inventory_update_webhook
```

Current `event_source` values:

```text
customer-feedback-webhook
inventory-update-webhook
```

The `event_source` field remains the preferred dashboard grouping field because it is concise and stable for comparing multiple workflows.


---

## Unauthorized Request Logging

The unauthorized branch logs requests that do not include the correct security header.

It inserts:

```text
workflow_name: customer_feedback_webhook
event_source: customer-feedback-webhook
execution_status: unauthorized
auth_status: unauthorized
response_status_code: 401
error_message: Unauthorized request
```

No customer or product fields are logged for unauthorized requests.

This is intentional because unauthorized payloads should not be trusted.

The response returns:

```json
{
  "auth_status": "unauthorized",
  "status": "error",
  "message": "Unauthorized request"
}
```

---

## Validation Error Logging

The validation error branch logs requests that pass authorization but fail payload validation.

It inserts:

```text
execution_status: validation_error
auth_status: authorized
payload_status: error
response_status_code: 400
customer_id: from request body
product_id: from request body
feedback_type: from request body
rating: from request body
error_message: validation errors joined into one text field
```

The error message expression used in n8n was:

```javascript
{{ $json.errors.join('; ') }}
```

The response returns:

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

## Successful Insert Logging

The success branch logs requests that pass authorization, pass validation, and insert into PostgreSQL.

It runs after:

```text
Insert Feedback to Postgres
```

It inserts:

```text
execution_status: success
auth_status: authorized
payload_status: success
response_status_code: 200
customer_id: from cleaned payload
product_id: from cleaned payload
feedback_type: from cleaned payload
rating: from cleaned payload
```

The response returns:

```json
{
  "status": "success",
  "message": "Customer feedback inserted into PostgreSQL"
}
```

---

## Important Fixes During Step 10

During testing, the first version of the log nodes accidentally mapped:

```text
log_id = 0
```

This caused a PostgreSQL primary key error:

```text
duplicate key value violates unique constraint "workflow_execution_logs_pkey"
```

The fix was to remove `log_id` from all n8n log nodes.

This lets PostgreSQL auto-generate the primary key through the `BIGSERIAL` column.

The bad test row was deleted with:

```sql
DELETE FROM workflow_execution_logs
WHERE log_id = 0;
```

The unauthorized log node also originally inserted fake values:

```text
customer_id = 0
product_id = 0
rating = 0
```

These were removed.

Unauthorized requests now leave those fields empty, which is more accurate.

---

## Test Results

Three tests were run.

### Test 1 — Unauthorized Request

Expected result:

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

### Test 2 — Authorized Invalid Payload

Expected result:

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

### Test 3 — Authorized Valid Payload

Expected result:

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

## Log Verification Query

Logs were verified with:

```sql
SELECT
    log_id,
    execution_status,
    auth_status,
    payload_status,
    response_status_code,
    customer_id,
    product_id,
    feedback_type,
    rating,
    error_message,
    created_at
FROM workflow_execution_logs
ORDER BY log_id DESC
LIMIT 10;
```

Verified result:

```text
3 | success          | authorized   | success | 200 | 3 | 5 | review     | 5 |
2 | validation_error | authorized   | error   | 400 | 3 | 5 | wrong_type | 9 | feedback_type must be one of: review, support_ticket, complaint, product_question; rating must be a number between 1 and 5; feedback_text is required and cannot be empty
1 | unauthorized     | unauthorized |         | 401 |   |   |            |   | Unauthorized request
```

This confirms that all three workflow branches are now logged correctly.

---

## What This Step Proves

Step 10 proves that the automation layer can now track its own activity in PostgreSQL.

The project now supports:

```text
Unauthorized request
→ 401 response
→ unauthorized log row
```

```text
Authorized but invalid request
→ 400 response
→ validation_error log row
```

```text
Authorized and valid request
→ customer_feedback insert
→ 200 response
→ success log row
```

This makes the workflow easier to debug, audit, and present as a portfolio project.

---

## Future Improvements

Possible future improvements include:

* adding a Metabase dashboard for workflow logs
* tracking execution duration
* storing n8n execution ID
* storing request source or IP address
* moving the webhook secret out of hardcoded JavaScript
* changing log-node error behavior so a logging failure does not block the webhook response
* creating alerting for repeated unauthorized requests
* creating a daily summary of workflow activity
