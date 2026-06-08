# Workflow Observability Dashboard

## Purpose

The **Workflow Observability Dashboard** is a Metabase dashboard created for monitoring the n8n customer feedback webhook workflow.

It provides a clear view of workflow activity by showing total executions, successful executions, unauthorized requests, validation errors, success rate, execution trends, status breakdowns, and recent workflow errors.

The dashboard is designed to make the automation layer easier to monitor, debug, and explain.

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

The source table was created in Step 10 and stores audit records for important n8n webhook execution paths.

The table logs:

```text
unauthorized requests
validation errors
successful customer feedback inserts
```

---

## SQL Views Created

Step 11 created four SQL views.

### 1. vw_workflow_execution_summary

**Purpose:** Provides high-level workflow execution KPIs.

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

### 2. vw_workflow_execution_daily

**Purpose:** Shows workflow execution volume by day and execution status.

Main columns:

```text
execution_date
execution_status
execution_count
```

This view is used for the workflow execution trend chart.

---

### 3. vw_workflow_status_breakdown

**Purpose:** Shows total workflow executions by status.

Main columns:

```text
execution_status
execution_count
execution_percent
```

This view is used for the status breakdown chart.

---

### 4. vw_workflow_recent_errors

**Purpose:** Shows recent failed or suspicious workflow activity.

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

## Dashboard Cards

### 1. Total Workflow Executions

**Purpose:** Shows the total number of logged workflow executions.

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

**Purpose:** Shows how many workflow executions completed successfully.

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

**Purpose:** Shows the percentage of workflow executions that completed successfully.

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

### 6. Workflow Executions Over Time

**Purpose:** Shows workflow execution volume over time, split by execution status.

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
Execution Status
```

---

### 7. Workflow Executions by Status

**Purpose:** Compares the number of workflow executions by status.

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
Execution Status
```

**Y-axis:**

```text
Execution Count
```

---

### 8. Latest Workflow Errors

**Purpose:** Shows recent unauthorized requests, validation errors, and other workflow errors.

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

## Dashboard Layout

The dashboard uses an observability-style layout:

```text
[ Total Workflow Executions ] [ Successful Workflow Executions ] [ Workflow Success Rate ]

[ Unauthorized Workflow Requests ] [ Workflow Validation Errors ]

[ Workflow Executions Over Time ]

[ Workflow Executions by Status ]

[ Latest Workflow Errors ]
```

The top row shows headline workflow KPIs.

The second row highlights the most important failure counters.

The middle section shows workflow activity over time.

The lower section shows execution status distribution and recent errors for debugging.

---

## Screenshot

![Workflow Observability Dashboard](../screenshots/metabase_workflow_observability_dashboard.png)


## Current Dashboard Values

At the time of creation, the dashboard showed:

```text
Total Workflow Executions: 6
Successful Workflow Executions: 2
Workflow Success Rate: 33.33
Unauthorized Workflow Requests: 2
Workflow Validation Errors: 2
```

These values come from local webhook tests that intentionally covered successful, unauthorized, and validation-error execution paths.

The logged execution paths include:

```text
unauthorized requests
authorized invalid payload requests
authorized valid payload requests
```

The success rate is low because the current dataset intentionally includes non-success test cases to demonstrate workflow monitoring and error visibility.

---

## What This Dashboard Proves

This dashboard demonstrates workflow observability for the automation layer of the project.

It shows that the project can:

```text
1. Capture n8n webhook activity in PostgreSQL
2. Separate successful executions from unauthorized and invalid requests
3. Transform workflow logs into analytics-ready SQL views
4. Use Metabase to monitor automation health
5. Surface recent workflow errors for debugging and auditability
```

This turns n8n workflow activity into a business-facing monitoring dashboard.

---

## Why This Matters

Before workflow logging, the workflow could process customer feedback, but its activity was only visible inside n8n.

After Step 10 and Step 11, workflow activity is visible in PostgreSQL and Metabase.

This means the platform can now answer operational questions such as:

```text
How many webhook requests were received?
How many succeeded?
How many failed authorization?
How many failed validation?
What was the latest workflow error?
When did the latest workflow execution happen?
```

This makes the automation layer more transparent and easier to maintain.

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
move webhook secrets fully into environment-based configuration
```
