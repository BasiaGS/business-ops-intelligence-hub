# Production Readiness Improvements for n8n Webhook Workflow

## Purpose

This document describes Step 12 of the Business Ops Intelligence Hub project.

In earlier steps, the customer feedback webhook was secured with a simple HTTP header, activated as a production webhook, logged into PostgreSQL, and monitored through a Metabase observability dashboard.

In Step 12, the webhook security configuration was improved by moving the expected webhook secret out of hardcoded JavaScript and into environment-based configuration.

This makes the workflow more production-like because the secret value is now managed through local environment configuration instead of being written directly inside the n8n Code node.

---

## Why This Improvement Was Needed

Before Step 12, the `Code - Check Secret` node used a hardcoded local demo secret:

```javascript
const expectedSecret = 'local-dev-secret';
```

This worked for local testing, but it is not a good production pattern.

Hardcoding secrets directly in workflow code has several problems:

```text
1. The secret is visible to anyone who can edit or export the workflow
2. The secret can accidentally be committed to Git
3. Secret rotation requires editing workflow logic
4. Local and production environments cannot easily use different secret values
```

Step 12 improves this by storing the secret value in environment configuration.

---

## Files Updated

Two project files were updated.

### 1. `.env.example`

A placeholder webhook secret was added:

```env
# n8n webhook security
WEBHOOK_SECRET=change_this_webhook_secret
```

This file is safe to commit because it contains only a placeholder value.

The real secret belongs in the local `.env` file, which should not be committed to Git.

---

### 2. `docker-compose.yml`

The n8n service now receives the webhook secret from the environment:

```yaml
WEBHOOK_SECRET: ${WEBHOOK_SECRET}
```

The n8n service also allows environment access inside the Code node:

```yaml
N8N_BLOCK_ENV_ACCESS_IN_NODE: "false"
```

This allows the workflow code to read the webhook secret through n8n's environment variable access.

---

## Local `.env` Configuration

The local `.env` file was updated with the real local development value:

```env
WEBHOOK_SECRET=local-dev-secret
```

This value is used only for local testing.

The `.env` file should not be committed to Git because it can contain real passwords and secrets.

---

## n8n Container Verification

After updating the environment configuration, the n8n container was restarted:

```bash
docker compose up -d n8n
```

The environment variable was verified inside the running container:

```bash
docker exec business_ops_n8n printenv WEBHOOK_SECRET
```

Expected result:

```text
local-dev-secret
```

This confirmed that Docker Compose passed the variable into the n8n container correctly.

---

## Updated n8n Code Node

The `Code - Check Secret` node was updated.

Before Step 12, the expected secret was hardcoded:

```javascript
const expectedSecret = 'local-dev-secret';
```

After Step 12, the expected secret is read from the environment:

```javascript
const expectedSecret = $env.WEBHOOK_SECRET;
```

Full updated code:

```javascript
const headers = $json.headers || {};

const providedSecret =
  headers['x-webhook-secret'] ||
  headers['X-Webhook-Secret'] ||
  headers['X-WEBHOOK-SECRET'];

const expectedSecret = $env.WEBHOOK_SECRET;

if (!expectedSecret || providedSecret !== expectedSecret) {
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

---

## Important n8n Note

The first attempted version used:

```javascript
process.env.WEBHOOK_SECRET
```

That did not work inside the n8n Code node.

The error was:

```text
process is not defined
```

The working n8n pattern was:

```javascript
$env.WEBHOOK_SECRET
```

This is the correct pattern used in this workflow.

---

## Workflow Structure After Step 12

The workflow structure stayed the same.

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

Step 12 changed how the expected secret is configured, not the business logic of the workflow.

---

## Test Results

All three webhook paths were retested after the environment-based secret update.

### Test 1 — Unauthorized Request

A request was sent without the required `x-webhook-secret` header.

Expected result:

```text
HTTP/1.1 401 Unauthorized
```

Actual result:

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

Confirmed workflow path:

```text
Webhook
→ Code - Check Secret
→ IF - Is Authorized?
→ false branch
→ Insert Unauthorized Log
→ Respond Unauthorized
```

---

### Test 2 — Authorized Invalid Payload

A request was sent with the correct `x-webhook-secret` header but with invalid payload values.

Expected result:

```text
HTTP/1.1 400 Bad Request
```

Actual result:

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

Confirmed workflow path:

```text
Webhook
→ Code - Check Secret
→ IF - Is Authorized?
→ true branch
→ Code - Validate and Clean Feedback
→ IF - Is Payload Valid?
→ false branch
→ Insert Validation Error Log
→ Respond with Validation Error to Webhook
```

---

### Test 3 — Authorized Valid Payload

A request was sent with the correct `x-webhook-secret` header and a valid payload.

Expected result:

```text
HTTP/1.1 200 OK
```

Actual result:

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

Confirmed workflow path:

```text
Webhook
→ Code - Check Secret
→ IF - Is Authorized?
→ true branch
→ Code - Validate and Clean Feedback
→ IF - Is Payload Valid?
→ true branch
→ Insert Feedback to Postgres
→ Insert Success Log
→ Respond Success
```

---

## PostgreSQL Log Verification

Workflow logs were verified with:

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

The newest Step 12 log rows were:

```text
log_id 6 | success          | authorized   | success | 200
log_id 5 | validation_error | authorized   | error   | 400
log_id 4 | unauthorized     | unauthorized |         | 401
```

This confirms that the environment-based secret update preserved all three workflow logging paths.

---

## Customer Feedback Verification

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

Confirmed newest row:

```text
feedback_id:      24
customer_id:      3
product_id:       5
feedback_date:    2026-06-04 15:30:00+00
feedback_type:    review
rating:           5
sentiment_label:  positive
feedback_text:    Environment-based webhook secret works correctly.
```

---

## What This Step Proves

Step 12 proves that:

```text
1. The webhook secret can be managed through environment configuration
2. The secret no longer needs to be hardcoded in the n8n Code node
3. Docker Compose can pass the webhook secret into the n8n container
4. n8n can read the secret through $env.WEBHOOK_SECRET
5. Unauthorized requests are still rejected with 401
6. Authorized invalid requests are still rejected with 400
7. Authorized valid requests still insert customer feedback into PostgreSQL
8. Workflow execution logs still capture all important execution paths
9. The workflow is now more production-like while remaining simple enough for a portfolio project
```

---

## Remaining Limitations

This is still a local portfolio project, not a full production security system.

Remaining limitations include:

```text
1. The webhook uses a shared secret, not request signing
2. There is no HMAC signature validation
3. There is no timestamp validation
4. There is no replay protection
5. There is no rate limiting
6. There is no IP allowlist
7. There is no automated alerting for repeated unauthorized requests
```

These are acceptable limitations for the current project stage.

---

## Recommended Future Improvements

Possible future improvements:

```text
1. Add HMAC request signing
2. Add timestamp validation to reduce replay risk
3. Add rate limiting if the webhook is exposed publicly
4. Add alerting for repeated unauthorized requests
5. Add alerting for repeated validation errors
6. Store request source metadata if available
7. Track n8n execution IDs in workflow_execution_logs
8. Track workflow execution duration
9. Export the n8n workflow JSON into the repository for version control
```

---

## Step 12 Result

Step 12 is complete.

The webhook workflow now uses an environment-based secret configuration while preserving the existing security, validation, PostgreSQL insertion, logging, and observability behavior.
