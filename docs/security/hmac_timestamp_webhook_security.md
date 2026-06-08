# HMAC and Timestamp Webhook Security Design

## Purpose

This document describes the planned security design for strengthening the Business Ops Intelligence Hub n8n webhook.

The current workflow uses a static shared secret header to reject unauthorized requests. This is useful for local development and portfolio demonstration, but a stronger production-style design should avoid relying only on a reusable static header.

The planned improvement is to use:

```text
HMAC request signing
timestamp validation
```

This document is design documentation only. The actual n8n workflow implementation will be handled in later steps.

---

## Current Security Model

The current customer feedback webhook expects a shared secret in this header:

```text
x-webhook-secret
```

Inside the n8n workflow, the Code node checks the provided header against the environment variable:

```javascript
$env.WEBHOOK_SECRET
```

Current behavior:

```text
Missing or incorrect secret
→ HTTP 401
→ unauthorized workflow log row

Correct secret and invalid payload
→ HTTP 400
→ validation error workflow log row

Correct secret and valid payload
→ PostgreSQL insert
→ success workflow log row
→ HTTP 200
```

This protects the webhook from basic unauthorized requests.

---

## Limitation of Static Shared Secret Header

A static shared secret header has one important weakness:

```text
The same secret value is sent with every request.
```

If that value is exposed, copied from logs, leaked from a client, or intercepted in an insecure environment, someone may reuse it to send unauthorized requests.

For a local portfolio project this is acceptable as a first security layer.

For a more production-aware design, the workflow should verify that each request was signed using the shared secret without requiring the secret itself to be sent as the authentication value.

---

## Planned Security Model

The planned model is:

```text
Client prepares request body
Client adds a timestamp
Client creates an HMAC signature from timestamp + request body
Client sends request body, timestamp, and signature
n8n recalculates the signature
n8n compares expected signature with provided signature
n8n checks that the timestamp is recent
n8n accepts or rejects the request
```

This gives two protections:

```text
HMAC signature
→ proves the sender knows the shared secret without sending the secret directly

Timestamp validation
→ limits how long a captured request can be reused
```

---

## Planned Headers

The future webhook should expect these headers:

```text
x-webhook-timestamp
x-webhook-signature
```

Optional during transition:

```text
x-webhook-secret
```

The static secret header may be kept temporarily during development, but the final stronger version should rely on HMAC signature verification.

---

## Planned Environment Variables

The n8n container should receive the shared signing secret through an environment variable.

Recommended variable:

```text
WEBHOOK_SIGNING_SECRET
```

Possible temporary compatibility variable:

```text
WEBHOOK_SECRET
```

Recommended future environment approach:

```text
WEBHOOK_SIGNING_SECRET=change_this_signing_secret
```

The real local value must stay in `.env`.

The safe placeholder should be documented in `.env.example`.

The real secret value must not be committed to Git.

---

## Signature Input Format

The client and server must agree on exactly what is signed.

Recommended signing input:

```text
timestamp + "." + raw_request_body
```

Example conceptual format:

```text
1717351200.{"customer_id":1,"product_id":2,"feedback_type":"review","rating":5,"feedback_text":"Great product"}
```

The exact JSON string matters. The safest approach is to sign the raw request body before it is parsed or reformatted.

If raw body handling is difficult in n8n, the implementation step should document the chosen compromise clearly.

---

## Signature Algorithm

Recommended algorithm:

```text
HMAC-SHA256
```

Conceptual client-side logic:

```text
signature = HMAC_SHA256(secret, timestamp + "." + raw_request_body)
```

The signature should be sent in the request header:

```text
x-webhook-signature
```

Recommended header value format:

```text
sha256=<hex_digest>
```

Example shape:

```text
sha256=example_signature_hash
```

Do not use a real secret or real production signature in documentation.

---

## Timestamp Validation

The request should include a Unix timestamp in seconds:

```text
x-webhook-timestamp
```

The receiving workflow should compare this timestamp with the current server time.

Recommended acceptance window:

```text
5 minutes
```

Conceptual validation:

```text
current_server_time - request_timestamp <= 300 seconds
```

If the timestamp is missing, invalid, or too old, the request should be rejected.

Recommended response:

```text
HTTP 401
```

Recommended log status:

```text
unauthorized
```

Possible error message:

```text
Invalid or expired request timestamp
```

---

## Replay Attack Protection

A replay attack means someone captures a valid request and sends it again later.

HMAC alone confirms that the request was signed correctly, but it does not automatically prove that the request is fresh.

Timestamp validation reduces this risk because an old captured request will expire.

Example:

```text
Request signed at 12:00
Allowed until 12:05
Rejected after 12:05
```

For stronger replay protection, the system could later store request IDs or nonces and reject duplicates.

That is not required for the next implementation step, but it is a possible future improvement.

---

## Planned n8n Verification Flow

Future workflow security path:

```text
Webhook
→ Code - Verify HMAC Signature and Timestamp
→ IF - Is Authorized?
    ├── false → Insert Unauthorized Log → Respond Unauthorized
    └── true  → Code - Validate and Clean Feedback
                → IF - Is Payload Valid?
                    ├── true  → Insert Feedback to Postgres → Insert Success Log → Respond Success
                    └── false → Insert Validation Error Log → Respond Validation Error
```

The current node:

```text
Code - Check Secret
```

will likely be replaced or renamed to:

```text
Code - Verify HMAC Signature and Timestamp
```

---

## Expected Unauthorized Cases

The future security node should reject requests when:

```text
x-webhook-signature is missing
x-webhook-timestamp is missing
timestamp is not a valid Unix timestamp
timestamp is outside the allowed time window
signature format is invalid
signature does not match the expected HMAC digest
signing secret is not configured in the n8n environment
```

---

## Expected Authorized Case

The request should be authorized only when:

```text
timestamp is present
timestamp is valid
timestamp is recent
signature is present
signature matches the expected HMAC digest
signing secret is configured
```

Only after authorization should the workflow validate and insert the customer feedback payload.

---

## Testing Strategy

Future implementation should test at least these cases:

```text
Missing signature
→ HTTP 401

Missing timestamp
→ HTTP 401

Expired timestamp
→ HTTP 401

Incorrect signature
→ HTTP 401

Valid signature but invalid payload
→ HTTP 400

Valid signature and valid payload
→ HTTP 200
```

Database checks should confirm that each important path writes a row into:

```text
workflow_execution_logs
```

---

## Secret-Safety Notes

Real signing secrets must not be committed to Git.

The exported n8n workflow should reference environment variables, not real secret values.

The workflow export should be checked before commit with:

```bash
bash scripts/check_workflow_secrets.sh
```

When Step 18 adds the new signing secret variable, the secret-check script may need to be updated to verify the new safe environment-variable reference.

---

## Implementation Scope

This document belongs to Step 17.

Step 17 includes:

```text
create this security design document
review the document
commit the document
```

Step 17 does not include:

```text
changing the n8n workflow
changing the webhook client
changing database tables
implementing HMAC verification
implementing timestamp validation
```

Those changes belong to later steps.

---

## Next Implementation Steps

Planned follow-up work:

```text
Step 18 — Implement HMAC request signing in the workflow
Step 19 — Add timestamp validation / replay protection
```
