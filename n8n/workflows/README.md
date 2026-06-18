# n8n Workflow Exports

This folder contains exported n8n workflow JSON files for the Business Ops Intelligence Hub project.

These files are version-controlled so the workflows can be reviewed, backed up, restored, and updated safely.

---

## Current Exported Workflows

```text
customer_feedback_webhook_workflow.json
inventory_update_webhook_workflow.json
```

The customer feedback workflow receives customer feedback through an n8n webhook, checks a security header, validates the payload, inserts valid feedback into PostgreSQL, logs workflow execution results, and returns an HTTP response.

The inventory update workflow receives inventory update data through an n8n webhook, checks the same security header pattern, validates the payload, updates an existing PostgreSQL inventory row, logs workflow execution results, and returns an HTTP response.

Main execution paths for both workflows:

```text
Unauthorized request
→ HTTP 401
→ workflow_execution_logs row

Authorized but invalid payload
→ HTTP 400
→ workflow_execution_logs row

Authorized and valid payload
→ PostgreSQL insert or update
→ workflow_execution_logs row
→ HTTP 200
```

---

## Restore / Import Notes

To restore a workflow in n8n:

```text
1. Start the Docker stack.
2. Open n8n at http://localhost:5678.
3. Import the required workflow JSON file:
   - customer_feedback_webhook_workflow.json
   - inventory_update_webhook_workflow.json
4. Review the imported workflow nodes and connections.
5. Reconnect or confirm the PostgreSQL credential.
6. Confirm WEBHOOK_SECRET exists in the n8n container environment.
7. Test the unauthorized request path.
8. Test the authorized invalid payload path.
9. Test the authorized valid payload path.
10. Activate or publish the workflow before using the production webhook URL.
```

Credentials may need to be reconnected manually after importing a workflow into a fresh n8n instance.

---

## Current Webhook Paths

Customer feedback workflow:

```text
Test URL:       /webhook-test/customer-feedback
Production URL: /webhook/customer-feedback
```

Inventory update workflow:

```text
Test URL:       /webhook-test/inventory-update
Production URL: /webhook/inventory-update
```

Important n8n distinction:

```text
/webhook-test/...  = used while testing inside n8n
/webhook/...       = production URL, works when the workflow is active/published
```

---

## Workflow Test Commands

Detailed local curl test commands are documented outside this export folder:

- docs/n8n/customer_feedback_workflow_tests.md
- docs/n8n/inventory_update_workflow_tests.md

These test documents cover:

successful requests
unauthorized requests
validation-error requests
PostgreSQL verification queries
workflow execution log verification

This folder stores exported workflow JSON files. The **detailed test instructions live in `docs/n8n`** so workflow exports and workflow documentation remain separated.

---


## Secret-Safety Checks

Do not commit real local secrets in exported workflow JSON or folder documentation.

After exporting or updating workflow JSON, run this from the project root:

```bash
bash scripts/check_workflow_secrets.sh
```

Or, if the script is executable:

```bash
./scripts/check_workflow_secrets.sh
```

The workflows should reference the webhook secret through the environment variable pattern:

```javascript
$env.WEBHOOK_SECRET
```

They should not contain the real local secret value.

Real local development secret values must not appear in exported workflow JSON or in this folder README.

---

## Export Update Process

When an n8n workflow changes:

```text
1. Export the updated workflow from n8n.
2. Replace the matching JSON file in this folder.
3. Run the workflow secret-check script.
4. Review the Git diff.
5. Commit the updated workflow JSON only if no real secrets are exposed.
```

Recommended verification:

```bash
bash scripts/check_workflow_secrets.sh
git status -sb
git diff
```

---

## Important Notes

The exported JSON files are useful for workflow backup and review, but they may not contain usable local credentials.

The workflow structures can be restored from these files, but PostgreSQL credentials may need to be selected again inside n8n after import.

Real `.env` values and local credentials should stay outside Git.

---

## Related Documentation

Customer feedback workflow documentation:

```text
docs/n8n/customer_feedback_workflow_tests.md
docs/n8n/webhook_customer_feedback_ingestion.md
docs/n8n/webhook_security_and_production_activation.md
docs/n8n/workflow_execution_logging.md
docs/n8n/workflow_export_and_version_control.md
```

Inventory update workflow documentation:

```text
docs/n8n/inventory_update_workflow.md
docs/n8n/inventory_update_workflow_tests.md
```
