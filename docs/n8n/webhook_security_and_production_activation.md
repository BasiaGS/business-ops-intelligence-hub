# Webhook Security Header and Production Activation

## Purpose

This document describes Step 9 of the Business Ops Intelligence Hub project.

In Step 8, the customer feedback webhook was created and tested with local test URLs. The workflow could receive customer feedback JSON, validate and clean the data, insert valid records into PostgreSQL, and reject invalid records.

In Step 9, a simple security layer was added before validation and database insertion.

The workflow now checks for a required HTTP header before accepting the request.

This makes the webhook more realistic and safer because unknown or unauthorized requests are stopped before they reach the validation logic or PostgreSQL.

---

## Workflow Name

```text
Webhook Based Injection Workflow w/Security Node
```

---

## Security Header

The workflow checks for this HTTP header:

```text
x-webhook-secret
```

Local demo value used during testing:

```text
local-dev-secret
```

Important:

```text
This local demo secret is acceptable for local testing and documentation.
A real production secret should not be committed to Git.
A real production secret should be stored in an environment variable or secret manager.
```

---

## Updated Workflow Structure

The Step 8 workflow structure was:

```text
Webhook
→ Code - Validate and Clean Feedback
→ IF - Is Payload Valid?
    ├── true  → Insert Feedback to Postgres → Respond Success
    └── false → Respond Validation Error
```

The Step 9 workflow structure is:

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

---

## Why the Security Check Was Added First

The authorization check happens before payload validation.

This is intentional.

It means:

```text
1. Unauthorized requests stop immediately
2. Unauthorized requests do not reach validation logic
3. Unauthorized requests do not reach PostgreSQL
4. Valid authorized requests continue normally
5. Invalid authorized requests still get a clear validation response
```

This creates a cleaner and safer workflow.

---

## Node 1 — Webhook

The Webhook node receives incoming HTTP POST requests.

Settings:

```text
HTTP Method: POST
Path: customer-feedback
Authentication: None
Respond: Using "Respond to Webhook" Node
```

Test URL:

```text
http://localhost:5678/webhook-test/customer-feedback
```

Production URL:

```text
http://localhost:5678/webhook/customer-feedback
```

Important n8n distinction:

```text
/webhook-test/...  = test URL, works when the workflow is listening for a test event
/webhook/...       = production URL, works only after the workflow is published/active
```

---

## Node 2 — Code: Check Secret

This node checks whether the incoming request includes the correct `x-webhook-secret` header.

Code used:

```javascript
const expectedSecret = 'local-dev-secret';

const headers = $json.headers || {};
const providedSecret =
  headers['x-webhook-secret'] ||
  headers['X-Webhook-Secret'] ||
  headers['X-WEBHOOK-SECRET'];

if (providedSecret !== expectedSecret) {
  return [
    {
      json: {
        auth_status: 'unauthorized',
        status: 'error',
        message: 'Unauthorized request'
      }
    }
  ];
}

return [
  {
    json: {
      auth_status: 'authorized',
      body: $json.body
    }
  }
];
```

If the header is missing or incorrect, the node returns:

```json
{
  "auth_status": "unauthorized",
  "status": "error",
  "message": "Unauthorized request"
}
```

If the header is correct, the node returns:

```json
{
  "auth_status": "authorized",
  "body": {
    "customer_id": 3,
    "product_id": 5,
    "feedback_type": "review",
    "rating": 5,
    "feedback_text": "Example feedback"
  }
}
```

The original request body is passed forward inside `body` so that the existing validation node can continue reading from:

```javascript
$json.body
```

---

## Node 3 — IF: Is Authorized?

This node decides whether the request is allowed to continue.

Condition:

```text
Value 1: {{ $json.auth_status }}
Operation: equals
Value 2: authorized
```

Logic:

```text
If auth_status = authorized:
    continue to validation

If auth_status = unauthorized:
    return 401 Unauthorized
```

---

## Node 4A — Respond Unauthorized

This node runs when the request does not include the correct security header.

Settings:

```text
Respond With: JSON
Response Code: 401
Response Body: {{ $json }}
```

Example response:

```json
{
  "auth_status": "unauthorized",
  "status": "error",
  "message": "Unauthorized request"
}
```

---

## Node 4B — Code: Validate and Clean Feedback

This existing validation node still checks and cleans the feedback payload.

It validates:

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

---

## Node 5 — IF: Is Payload Valid?

This node decides whether valid feedback should be inserted into PostgreSQL.

Condition:

```text
Value 1: {{ $json.status }}
Operation: equals
Value 2: success
```

Logic:

```text
If status = success:
    insert into PostgreSQL

If status = error:
    return validation error
```

---

## Node 6A — Insert Feedback to Postgres

This node inserts valid authorized feedback into PostgreSQL.

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

PostgreSQL automatically generates:

```text
feedback_id
created_at
```

---

## Node 6B — Respond with Validation Error to Webhook

This node runs when the request is authorized but the payload is invalid.

Settings:

```text
Respond With: JSON
Response Code: 400
Response Body: {{ $json }}
```

Example response:

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

## Node 7 — Respond to Webhook: Success Response

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

## Test 1 — Unauthorized Request

This test sends a request without the required secret header.

Command:

```bash
curl -i -X POST "http://localhost:5678/webhook-test/customer-feedback" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": 3,
    "product_id": 5,
    "feedback_type": "review",
    "rating": 4,
    "feedback_text": "Unauthorized test."
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

This confirms that requests without the correct header are stopped before validation and before PostgreSQL.

---

## Test 2 — Authorized Valid Request

This test sends a valid request with the correct security header.

Command:

```bash
curl -i -X POST "http://localhost:5678/webhook-test/customer-feedback" \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: local-dev-secret" \
  -d '{
    "customer_id": 3,
    "product_id": 5,
    "feedback_date": "2026-05-30T13:00:00+02:00",
    "feedback_type": "review",
    "rating": 5,
    "feedback_text": "Webhook security header and insert branch work correctly."
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

This confirms that authorized valid data reaches PostgreSQL.

---

## Test 3 — Authorized Invalid Request

This test sends an invalid payload with the correct security header.

Command:

```bash
curl -i -X POST "http://localhost:5678/webhook-test/customer-feedback" \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: local-dev-secret" \
  -d '{
    "customer_id": 3,
    "product_id": 5,
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

This confirms that authorized but invalid data is rejected before PostgreSQL.

---

## PostgreSQL Verification After Test Insert

The valid authorized test inserted a new row into `customer_feedback`.

Verification query:

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

Confirmed inserted row:

```text
feedback_id:      20
customer_id:      3
product_id:       5
feedback_date:    2026-05-30 11:00:00+00
feedback_type:    review
rating:           5
sentiment_label:  positive
feedback_text:    Webhook security header and insert branch work correctly.
```

---

## Analytics View Verification

The dashboard-facing analytics view was also checked.

Query:

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

Confirmed result:

```text
product_id:             5
product_name:           Eco Laundry Detergent Sheets
feedback_count:         7
positive_count:         6
neutral_count:          0
negative_count:         1
average_rating:         4.00
latest_feedback_date:   2026-05-30 11:00:00+00
```

This confirms that newly inserted feedback is reflected in the analytics layer used by Metabase.

---

## Production Webhook Activation

After test mode worked, the workflow was published in n8n.

In this n8n version, publishing the workflow makes the production webhook active.

Production URL:

```text
http://localhost:5678/webhook/customer-feedback
```

Production test command:

```bash
curl -i -X POST "http://localhost:5678/webhook/customer-feedback" \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: local-dev-secret" \
  -d '{
    "customer_id": 3,
    "product_id": 5,
    "feedback_date": "2026-05-30T13:00:00+02:00",
    "feedback_type": "review",
    "rating": 5,
    "feedback_text": "Production webhook with security header works correctly."
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

The n8n Executions tab confirmed that the production execution succeeded.

Example execution:

```text
Jun 1, 18:06:30
Succeeded in 107ms
```

---

## PostgreSQL Verification After Production Insert

Verification query:

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

Confirmed newest production row:

```text
feedback_id:      21
customer_id:      3
product_id:       5
feedback_date:    2026-05-30 11:00:00+00
feedback_type:    review
rating:           5
sentiment_label:  positive
feedback_text:    Production webhook with security header works correctly.
```

---

## What This Step Proves

This step proves that:

```text
1. The n8n webhook can reject unauthorized requests
2. A custom HTTP header can be used as a simple shared-secret security check
3. Unauthorized requests stop before validation and database insertion
4. Authorized valid requests can still insert records into PostgreSQL
5. Authorized invalid requests still receive proper validation errors
6. The production webhook URL works after publishing the workflow
7. Production executions can be reviewed in the n8n Executions tab
8. PostgreSQL receives production webhook data correctly
9. Analytics views reflect newly inserted feedback data
```

---

## Current Limitations

The current security approach is simple and appropriate for a local portfolio project, but it is not a full production security design.

Limitations:

```text
1. The demo secret is hardcoded in the Code node
2. There is no request signing
3. There is no timestamp validation
4. There is no replay protection
5. There is no rate limiting
6. There is no IP allowlist
```

---

## Recommended Future Improvements

Recommended improvements:

```text
1. Move the webhook secret into an environment variable
2. Use n8n credentials or environment configuration instead of hardcoding secrets
3. Add duplicate detection for repeated feedback submissions
4. Add a workflow execution log table in PostgreSQL
5. Add better error handling for foreign key violations
6. Add request signing with HMAC for stronger webhook authentication
7. Add rate limiting if exposed publicly
8. Connect the webhook to a real form or frontend
9. Add AI-assisted feedback categorization later
```
