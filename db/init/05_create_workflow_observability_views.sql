-- ============================================================
-- EcoHome Supplies - Workflow Observability Views
-- Project: business-ops-intelligence-hub
-- Database: business_ops
-- ============================================================

-- These views prepare n8n workflow execution logs for Metabase.
-- They make webhook activity easier to monitor, debug, and explain.


-- ============================================================
-- 1. Workflow Execution Summary
-- Purpose:
-- Provides high-level workflow execution KPIs.
-- Useful for headline dashboard cards.
-- ============================================================

CREATE OR REPLACE VIEW vw_workflow_execution_summary AS
SELECT
    COUNT(*) AS total_executions,

    COUNT(*) FILTER (
        WHERE execution_status = 'success'
    ) AS successful_executions,

    COUNT(*) FILTER (
        WHERE execution_status = 'unauthorized'
    ) AS unauthorized_executions,

    COUNT(*) FILTER (
        WHERE execution_status = 'validation_error'
    ) AS validation_error_executions,

    COUNT(*) FILTER (
        WHERE execution_status = 'error'
    ) AS error_executions,

    ROUND(
        COUNT(*) FILTER (WHERE execution_status = 'success')::NUMERIC
        / NULLIF(COUNT(*), 0)
        * 100,
        2
    ) AS success_rate_percent,

    MAX(created_at) AS latest_execution_at
FROM workflow_execution_logs;


-- ============================================================
-- 2. Workflow Execution Daily
-- Purpose:
-- Shows workflow execution volume by day and status.
-- Useful for time-series charts in Metabase.
-- ============================================================

CREATE OR REPLACE VIEW vw_workflow_execution_daily AS
SELECT
    DATE(created_at) AS execution_date,
    execution_status,
    COUNT(*) AS execution_count
FROM workflow_execution_logs
GROUP BY
    DATE(created_at),
    execution_status
ORDER BY
    execution_date,
    execution_status;


-- ============================================================
-- 3. Workflow Status Breakdown
-- Purpose:
-- Shows the total number of executions by status.
-- Useful for bar charts or pie charts.
-- ============================================================

CREATE OR REPLACE VIEW vw_workflow_status_breakdown AS
SELECT
    execution_status,
    COUNT(*) AS execution_count,
    ROUND(
        COUNT(*)::NUMERIC
        / NULLIF((SELECT COUNT(*) FROM workflow_execution_logs), 0)
        * 100,
        2
    ) AS execution_percent
FROM workflow_execution_logs
GROUP BY
    execution_status
ORDER BY
    execution_count DESC;


-- ============================================================
-- 4. Recent Workflow Errors
-- Purpose:
-- Shows recent failed or suspicious workflow activity.
-- Useful for table cards in Metabase.
-- ============================================================

CREATE OR REPLACE VIEW vw_workflow_recent_errors AS
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
WHERE execution_status IN ('unauthorized', 'validation_error', 'error')
ORDER BY created_at DESC;


-- ============================================================
-- End of workflow observability views
-- ============================================================
