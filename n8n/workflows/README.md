# n8n Workflow Exports

This folder contains exported n8n workflow JSON files for the Business Ops Intelligence Hub project.

These files are version-controlled so the workflows can be reviewed, backed up, restored, and updated safely.

---

## Current Exported Workflow

```text
customer_feedback_webhook_workflow.json
```

This workflow receives customer feedback through an n8n webhook, checks a security header, validates the payload, inserts valid feedback into PostgreSQL, logs workflow execution results, and returns an HTTP response.

Main execution paths:

```text
Unauthorized request
→ HTTP 401
→ workflow_execution_logs row

Authorized but invalid payload
→ HTTP 400
→ workflow_execution_logs row

Authorized and valid payload
→ customer_feedback insert
→ workflow_execution_logs row
→ HTTP 200
```

---

## Restore / Import Notes

To restore the workflow in n8n:

```text
1. Start the Docker stack.
2. Open n8n at http://localhost:5678.
3. Import customer_feedback_webhook_workflow.json.
4. Review the imported workflow nodes and connections.
5. Reconnect or confirm the PostgreSQL credential.
6. Confirm WEBHOOK_SECRET exists in the n8n container environment.
7. Test the unauthorized request path.
8. Test the authorized invalid payload path.
9. Test the authorized valid payload path.
10. Activate or publish the workflow before using the production webhook URL.
```

Credentials may need to be reconnected manually after importing the workflow into a fresh n8n instance.

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

The workflow should reference the webhook secret through the environment variable pattern:

```javascript
$env.WEBHOOK_SECRET
```

It should not contain the real local secret value.

Real local development secret values must not appear in exported workflow JSON or in this folder README.

---

## Export Update Process

When the n8n workflow changes:

```text
1. Export the updated workflow from n8n.
2. Replace the existing JSON file in this folder.
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

The exported JSON is useful for workflow backup and review, but it may not contain usable local credentials.

The workflow structure can be restored from this file, but PostgreSQL credentials may need to be selected again inside n8n after import.

Real `.env` values and local credentials should stay outside Git.
