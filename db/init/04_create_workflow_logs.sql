-- ============================================================
-- EcoHome Supplies - Workflow Execution Logs
-- Project: business-ops-intelligence-hub
-- Database: business_ops
-- ============================================================

-- This table stores audit logs for n8n workflow executions.
-- It helps track successful webhook requests, validation errors,
-- unauthorized requests, and production activity.

CREATE TABLE IF NOT EXISTS workflow_execution_logs (
    log_id BIGSERIAL PRIMARY KEY,

    workflow_name TEXT NOT NULL,
    event_source TEXT NOT NULL,

    execution_status TEXT NOT NULL,
    auth_status TEXT,
    payload_status TEXT,

    response_status_code INTEGER,

    customer_id BIGINT,
    product_id BIGINT,
    feedback_type TEXT,
    rating INTEGER,

    error_message TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT workflow_execution_status_check
        CHECK (execution_status IN ('success', 'unauthorized', 'validation_error', 'error')),

    CONSTRAINT workflow_auth_status_check
        CHECK (auth_status IS NULL OR auth_status IN ('authorized', 'unauthorized')),

    CONSTRAINT workflow_payload_status_check
        CHECK (payload_status IS NULL OR payload_status IN ('success', 'error')),

    CONSTRAINT workflow_response_status_code_check
        CHECK (
            response_status_code IS NULL
            OR response_status_code BETWEEN 100 AND 599
        )
);

CREATE INDEX IF NOT EXISTS idx_workflow_execution_logs_created_at
    ON workflow_execution_logs(created_at);

CREATE INDEX IF NOT EXISTS idx_workflow_execution_logs_execution_status
    ON workflow_execution_logs(execution_status);

CREATE INDEX IF NOT EXISTS idx_workflow_execution_logs_response_status_code
    ON workflow_execution_logs(response_status_code);

-- ============================================================
-- End of workflow execution logs
-- ============================================================
