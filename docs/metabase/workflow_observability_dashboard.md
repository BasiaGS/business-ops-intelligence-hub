# Workflow Observability Dashboard

## Purpose

The **Workflow Observability Dashboard** is a Metabase dashboard created for monitoring n8n webhook workflow activity.

It now supports multi-workflow observability. This means the dashboard can compare execution activity across more than one automation, including:

```text
customer-feedback-webhook
inventory-update-webhook
```

The dashboard provides a clear view of workflow activity by showing total executions, successful executions, unauthorized requests, validation errors, success rate, execution trends, status breakdowns, workflow comparison metrics, and recent workflow errors.

The dashboard is designed to make the automation layer easier to monitor, debug, compare, and explain.

---

## Dashboard Tool

The dashboard was created in:

```text
Metabase
```

Metabase is used as the business intelligence layer for the project. It connects to the PostgreSQL database running inside the Docker Compose stack.

Connection target:

```text
PostgreSQL database: business_ops
Docker service/container: business_ops_postgres
Metabase container: business_ops_metabase
```

Inside Docker, Metabase connects to PostgreSQL through the container/service name:

```text
business_ops_postgres:5432
```

This is used instead of `localhost` because Metabase runs inside its own container.

---

## Dashboard Name

```text
Workflow Observability Dashboard
```

Location in Metabase:

```text
Our analytics
```

---

## Data Source

The dashboard uses workflow observability views created in:

```text
db/init/05_create_workflow_observability_views.sql
```

These views prepare dashboard-ready summaries from the workflow execution logging table.

Source table:

```text
workflow_execution_logs
```

The source table stores audit records for important n8n webhook execution paths.

The table currently logs:

```text
unauthorized requests
validation errors
successful workflow executions
workflow-level identifiers
HTTP response status codes
recent error messages
```

---

## Current Logged Workflows

The current observability layer includes logs from two n8n workflows:

```text
customer-feedback-webhook
inventory-update-webhook
```

The workflow logs contain both `workflow_name` and `event_source`.

For dashboard grouping, `event_source` is the preferred workflow identifier because it is consistent across the current workflow logs.

Current event sources:

```text
customer-feedback-webhook
inventory-update-webhook
```

---

## SQL Views Created

Step 19 extends the observability views so they can support multiple workflows.

### 1. vw_workflow_execution_summary

**Purpose:** Provides global high-level workflow execution KPIs across all workflows.

Main metrics:

```text
total_executions
successful_executions
unauthorized_executions
validation_error_executions
error_executions
success_rate_percent
latest_execution_at
```

This view is used for the headline KPI cards.

---

### 2. vw_workflow_comparison

**Purpose:** Compares workflow activity and reliability by workflow.

Main columns:

```text
event_source
workflow_name
total_executions
successful_executions
unauthorized_executions
validation_error_executions
error_executions
success_rate_percent
latest_execution_at
```

This view is used for workflow comparison cards and tables.

---

### 3. vw_workflow_execution_daily

**Purpose:** Shows workflow execution volume by day, workflow, and execution status.

Main columns:

```text
execution_date
event_source
workflow_name
execution_status
execution_count
```

This view is used for workflow execution trend charts.

---

### 4. vw_workflow_status_breakdown

**Purpose:** Shows execution status breakdown by workflow.

Main columns:

```text
event_source
workflow_name
execution_status
execution_count
execution_percent_within_workflow
```

This view is used for grouped status breakdown charts.

---

### 5. vw_workflow_recent_errors

**Purpose:** Shows recent failed or suspicious workflow activity across all workflows.

Main columns:

```text
log_id
created_at
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
```

This view is used for the latest workflow errors table.

---

### 6. vw_workflow_recent_activity

**Purpose:** Shows the latest workflow executions across all workflows.

Main columns:

```text
log_id
created_at
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
```

This view is used for recent workflow activity and audit/debugging tables.

---

## Recommended Dashboard Cards

### 1. Total Workflow Executions

**Purpose:** Shows the total number of logged workflow executions across all workflows.

**Metabase visualization:**

```text
Number
```

**Source view:**

```text
vw_workflow_execution_summary
```

**Metric:**

```text
Total Executions
```

---

### 2. Successful Workflow Executions

**Purpose:** Shows how many workflow executions completed successfully across all workflows.

**Metabase visualization:**

```text
Number
```

**Source view:**

```text
vw_workflow_execution_summary
```

**Metric:**

```text
Successful Executions
```

---

### 3. Workflow Success Rate

**Purpose:** Shows the percentage of all workflow executions that completed successfully.

**Metabase visualization:**

```text
Number
```

**Source view:**

```text
vw_workflow_execution_summary
```

**Metric:**

```text
Success Rate Percent
```

---

### 4. Unauthorized Workflow Requests

**Purpose:** Shows how many webhook requests failed the security header check.

**Metabase visualization:**

```text
Number
```

**Source view:**

```text
vw_workflow_execution_summary
```

**Metric:**

```text
Unauthorized Executions
```

---

### 5. Workflow Validation Errors

**Purpose:** Shows how many authorized requests failed payload validation.

**Metabase visualization:**

```text
Number
```

**Source view:**

```text
vw_workflow_execution_summary
```

**Metric:**

```text
Validation Error Executions
```

---

### 6. Workflow Comparison

**Purpose:** Compares total executions, success count, unauthorized count, validation-error count, error count, success rate, and latest execution time by workflow.

**Metabase visualization:**

```text
Table
```

**Source view:**

```text
vw_workflow_comparison
```

**Recommended displayed columns:**

```text
Event Source
Total Executions
Successful Executions
Unauthorized Executions
Validation Error Executions
Error Executions
Success Rate Percent
Latest Execution At
```

---

### 7. Success Rate by Workflow

**Purpose:** Compares workflow reliability by showing success rate for each workflow.

**Metabase visualization:**

```text
Bar chart
```

**Source view:**

```text
vw_workflow_comparison
```

**X-axis:**

```text
Event Source
```

**Y-axis:**

```text
Success Rate Percent
```

---

### 8. Daily Executions by Workflow

**Purpose:** Shows workflow execution volume over time, split by workflow and execution status.

**Metabase visualization:**

```text
Line chart
```

**Source view:**

```text
vw_workflow_execution_daily
```

**X-axis:**

```text
Execution Date
```

**Y-axis:**

```text
Execution Count
```

**Series / breakout:**

```text
Event Source
Execution Status
```

---

### 9. Workflow Executions by Status

**Purpose:** Compares execution statuses within each workflow.

**Metabase visualization:**

```text
Bar chart
```

**Source view:**

```text
vw_workflow_status_breakdown
```

**X-axis:**

```text
Event Source
```

**Y-axis:**

```text
Execution Count
```

**Series / breakout:**

```text
Execution Status
```

---

### 10. Latest Workflow Errors

**Purpose:** Shows recent unauthorized requests, validation errors, and other workflow errors across all workflows.

**Metabase visualization:**

```text
Table
```

**Source view:**

```text
vw_workflow_recent_errors
```

**Displayed columns:**

```text
Created At
Event Source
Execution Status
Response Status Code
Customer ID
Product ID
Feedback Type
Rating
Error Message
```

**Sort:**

```text
Created At descending
```

---

### 11. Recent Workflow Activity

**Purpose:** Shows the latest workflow executions across all workflows, including successful and failed paths.

**Metabase visualization:**

```text
Table
```

**Source view:**

```text
vw_workflow_recent_activity
```

**Displayed columns:**

```text
Created At
Event Source
Execution Status
Auth Status
Payload Status
Response Status Code
Customer ID
Product ID
Error Message
```

**Sort:**

```text
Created At descending
```

---

## Recommended Dashboard Filter

The dashboard should include a filter for:

```text
event_source
```

This allows the dashboard user to inspect:

```text
all workflows
customer-feedback-webhook only
inventory-update-webhook only
```

---

## Recommended Dashboard Layout

The dashboard should use an observability-style layout:

```text
[ Total Workflow Executions ] [ Successful Workflow Executions ] [ Workflow Success Rate ]

[ Unauthorized Workflow Requests ] [ Workflow Validation Errors ]

[ Workflow Comparison ]

[ Success Rate by Workflow ]

[ Daily Executions by Workflow ]

[ Workflow Executions by Status ]

[ Latest Workflow Errors ]

[ Recent Workflow Activity ]
```

The top row shows global headline KPIs.

The second row highlights the most important failure counters.

The comparison section shows how each workflow performs.

The trend section shows workflow activity over time.

The lower section shows recent errors and recent activity for debugging.

---

## Screenshot

![Workflow Observability Dashboard](../screenshots/metabase_workflow_observability_dashboard.png)

The screenshot may show the earlier single-workflow dashboard layout. Step 19 updates the SQL and documentation so the dashboard can be extended to compare multiple workflows.

---

## Current Dashboard Values

At the time of Step 19 validation, the workflow comparison view showed local test data for both workflows:

```text
customer-feedback-webhook: 25 total executions, 7 successful executions, 28.00 success rate
inventory-update-webhook: 4 total executions, 2 successful executions, 50.00 success rate
```

These values come from local webhook tests that intentionally covered successful, unauthorized, and validation-error execution paths.

The success rates are low because the current dataset intentionally includes non-success test cases to demonstrate workflow monitoring and error visibility.

---

## What This Dashboard Proves

This dashboard demonstrates multi-workflow observability for the automation layer of the project.

It shows that the project can:

```text
1. Capture n8n webhook activity in PostgreSQL
2. Monitor more than one business automation
3. Separate successful executions from unauthorized and invalid requests
4. Compare workflow health by workflow/event source
5. Transform workflow logs into analytics-ready SQL views
6. Use Metabase to monitor automation health
7. Surface recent workflow errors and recent activity for debugging and auditability
```

This turns n8n workflow activity into a business-facing monitoring layer.

---

## Why This Matters

Before workflow logging, workflow activity was mainly visible inside n8n.

After Step 10 and Step 11, workflow activity became visible in PostgreSQL and Metabase.

After Step 19, the observability layer can compare multiple workflows instead of only reporting one global summary.

This means the platform can now answer operational questions such as:

```text
How many webhook requests were received?
How many succeeded?
How many failed authorization?
How many failed validation?
Which workflow receives the most requests?
Which workflow has the highest success rate?
Which workflow has the most validation errors?
What was the latest workflow error across all workflows?
When did each workflow last run?
```

This makes the automation layer more transparent, easier to maintain, and easier to explain as a portfolio project.

---

## Future Improvements

Possible future improvements include:

```text
track n8n execution ID
track workflow execution duration
store request source or IP address
add alerting for repeated unauthorized requests
add alerting for repeated validation errors
add a daily or weekly workflow health summary
create separate dashboards for production and test workflows
```
