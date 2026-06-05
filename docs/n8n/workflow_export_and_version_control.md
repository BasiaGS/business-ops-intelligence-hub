# n8n Workflow Export and Version Control

## Purpose

This document describes Step 13 of the Business Ops Intelligence Hub project.

In earlier steps, the customer feedback workflow was built, secured, activated as a production webhook, connected to PostgreSQL logging, monitored through Metabase, and improved with environment-based secret configuration.

In Step 13, the current n8n workflow was exported as a JSON file and saved in the project repository.

This makes the n8n automation layer easier to back up, review, restore, and version-control.

---

## Why Workflow Export Matters

n8n workflows are created and edited inside the n8n UI.

Without an exported workflow file, the workflow mainly lives inside n8n's internal state.

That means the project documentation can describe the workflow, but the actual workflow definition is not fully represented in Git.

Exporting the workflow JSON solves this problem.

It allows the project to keep a version-controlled copy of:

```text
workflow nodes
node connections
node names
node settings
Code node logic
Postgres insert mappings
Respond to Webhook responses
sticky note documentation
```

This is important because the workflow is now part of the project architecture, not just a temporary UI configuration.

---

## Exported Workflow File

The exported workflow JSON is stored here:

```text
n8n/workflows/customer_feedback_webhook_workflow.json
```

The file contains the current customer feedback webhook workflow.

Current workflow structure:

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

## What the Workflow Does

The workflow receives customer feedback through an n8n webhook.

It then:

```text
1. Checks the x-webhook-secret HTTP header
2. Rejects unauthorized requests with HTTP 401
3. Validates authorized customer feedback payloads
4. Rejects invalid payloads with HTTP 400
5. Inserts valid customer feedback into PostgreSQL
6. Logs unauthorized requests, validation errors, and successful inserts
7. Returns a clear JSON response to the webhook caller
```

This supports the full automation path:

```text
External JSON request
→ n8n webhook
→ security check
→ validation
→ PostgreSQL insert
→ workflow execution log
→ Metabase observability
```

---

## Secret Handling

The exported workflow was checked to make sure it does not contain the real local webhook secret.

The workflow should not contain:

```text
local-dev-secret
```

The secret value belongs in the local `.env` file, not in Git.

The workflow Code node should reference the environment variable instead:

```javascript
const expectedSecret = $env.WEBHOOK_SECRET;
```

This means the workflow can use different secret values in different environments without changing the workflow logic.

---

## Verification Checks

After exporting the workflow, the file location was verified with:

```bash
ls -la n8n/workflows
```

Expected file:

```text
customer_feedback_webhook_workflow.json
```

The exported workflow was checked for accidental secret exposure:

```bash
grep -R "local-dev-secret" -n n8n/workflows
```

Expected result:

```text
No output
```

The exported workflow was also checked for the environment variable reference:

```bash
grep -R "WEBHOOK_SECRET" -n n8n/workflows
```

Expected result:

```text
The workflow JSON references WEBHOOK_SECRET through $env.WEBHOOK_SECRET.
```

---

## How to Export the Workflow Again

To export the workflow again from n8n:

```text
1. Open n8n
2. Open the customer feedback webhook workflow
3. Make any required workflow or sticky note updates
4. Use the workflow menu to download or export the workflow as JSON
5. Save the file as:
   n8n/workflows/customer_feedback_webhook_workflow.json
6. Run the secret checks again
7. Commit the updated JSON file
```

Exact menu wording may vary depending on the n8n version.

---

## How to Import the Workflow Later

To restore or reuse the workflow later:

```text
1. Open n8n
2. Choose the import workflow option
3. Select:
   n8n/workflows/customer_feedback_webhook_workflow.json
4. Review the imported nodes and connections
5. Confirm the Postgres credential is configured correctly
6. Confirm WEBHOOK_SECRET exists in the n8n container environment
7. Test the webhook paths before using the production webhook URL
```

The workflow depends on the project PostgreSQL database and n8n environment configuration.

---

## Related Environment Configuration

The local `.env` file should contain the real local development value:

```env
WEBHOOK_SECRET=local-dev-secret
```

The `.env.example` file should only contain a safe placeholder:

```env
WEBHOOK_SECRET=change_this_webhook_secret
```

The n8n service in `docker-compose.yml` passes the variable into the container:

```yaml
WEBHOOK_SECRET: ${WEBHOOK_SECRET}
N8N_BLOCK_ENV_ACCESS_IN_NODE: "false"
```

This allows the n8n Code node to read:

```javascript
$env.WEBHOOK_SECRET
```

---

## What This Step Proves

Step 13 proves that the n8n workflow is no longer only stored inside the n8n UI.

The project now has a version-controlled workflow definition that can be reviewed, backed up, restored, and updated through Git.

This improves the project by adding:

```text
1. Workflow backup
2. Workflow version control
3. Easier project review
4. Easier restore process
5. Better portfolio documentation
6. Safer secret handling verification
```

---

## Remaining Limitations

The exported workflow JSON may still depend on local n8n configuration, especially credentials.

The JSON can preserve workflow structure and node settings, but a restored workflow may still require:

```text
1. Reconnecting credentials
2. Confirming PostgreSQL access
3. Confirming environment variables
4. Testing webhook URLs
5. Publishing or activating the workflow
```

This is normal for n8n workflow exports.

---

## Future Improvements

Possible future improvements include:

```text
1. Add a README inside n8n/workflows
2. Export future workflows into the same folder
3. Add workflow naming conventions
4. Add restore instructions for a fresh environment
5. Add automated checks for accidental secret exposure
6. Add workflow export reminders after major n8n UI changes
```

---

## Step 13 Result

Step 13 is complete when:

```text
1. n8n/workflows/customer_feedback_webhook_workflow.json exists
2. docs/n8n/workflow_export_and_version_control.md exists
3. The exported JSON does not contain the real local secret
4. The exported JSON references WEBHOOK_SECRET
5. Both files are committed and pushed to GitHub
```
