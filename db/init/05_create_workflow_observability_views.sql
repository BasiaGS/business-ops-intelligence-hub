-- ============================================================
-- EcoHome Supplies - Workflow Observability Views
-- Project: business-ops-intelligence-hub
-- Database: business_ops
-- ============================================================

-- These views prepare n8n workflow execution logs for Metabase.
-- They make webhook activity easier to monitor, debug, compare,
-- and explain across multiple workflows.



-- Drop existing views first so this file can be safely re-run
-- after changing view columns during local development.

DROP VIEW IF EXISTS vw_workflow_recent_activity;
DROP VIEW IF EXISTS vw_workflow_recent_errors;
DROP VIEW IF EXISTS vw_workflow_status_breakdown;
DROP VIEW IF EXISTS vw_workflow_execution_daily;
DROP VIEW IF EXISTS vw_workflow_comparison;
DROP VIEW IF EXISTS vw_workflow_execution_summary;



-- ============================================================
-- 1. Workflow Execution Summary
-- Purpose:
-- Provides global high-level workflow execution KPIs.
-- Useful for headline dashboard cards across all workflows.
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
-- 2. Workflow Comparison
-- Purpose:
-- Compares workflow activity and reliability by workflow.
-- Uses event_source as the main grouping field because it is
-- consistent across the current customer-feedback and
-- inventory-update workflow logs.
-- ============================================================

CREATE OR REPLACE VIEW vw_workflow_comparison AS
SELECT
    event_source,

    MIN(workflow_name) AS workflow_name,

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
FROM workflow_execution_logs
GROUP BY
    event_source
ORDER BY
    event_source;


-- ============================================================
-- 3. Workflow Execution Daily
-- Purpose:
-- Shows workflow execution volume by day, workflow, and status.
-- Useful for time-series charts in Metabase.
-- ============================================================

CREATE OR REPLACE VIEW vw_workflow_execution_daily AS
SELECT
    DATE(created_at) AS execution_date,
    event_source,
    workflow_name,
    execution_status,
    COUNT(*) AS execution_count
FROM workflow_execution_logs
GROUP BY
    DATE(created_at),
    event_source,
    workflow_name,
    execution_status
ORDER BY
    execution_date,
    event_source,
    execution_status;


-- ============================================================
-- 4. Workflow Status Breakdown
-- Purpose:
-- Shows the total number of executions by workflow and status.
-- Useful for stacked bar charts or grouped status comparisons.
-- ============================================================

CREATE OR REPLACE VIEW vw_workflow_status_breakdown AS
SELECT
    event_source,
    workflow_name,
    execution_status,
    COUNT(*) AS execution_count,
    ROUND(
        COUNT(*)::NUMERIC
        / NULLIF(
            SUM(COUNT(*)) OVER (PARTITION BY event_source),
            0
        )
        * 100,
        2
    ) AS execution_percent_within_workflow
FROM workflow_execution_logs
GROUP BY
    event_source,
    workflow_name,
    execution_status
ORDER BY
    event_source,
    execution_count DESC;


-- ============================================================
-- 5. Recent Workflow Errors
-- Purpose:
-- Shows recent failed or suspicious workflow activity across
-- all workflows.
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
-- 6. Recent Workflow Activity
-- Purpose:
-- Shows the latest workflow executions across all workflows.
-- Useful for audit/debugging tables in Metabase.
-- ============================================================

CREATE OR REPLACE VIEW vw_workflow_recent_activity AS
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
ORDER BY created_at DESC;


-- ============================================================
-- End of workflow observability views
-- ============================================================
