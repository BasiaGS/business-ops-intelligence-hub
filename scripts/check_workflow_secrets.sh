#!/usr/bin/env bash

set -euo pipefail

WORKFLOW_DIR="n8n/workflows"

echo "Checking exported n8n workflows for unsafe secret exposure..."
echo

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1"
  exit 1
}

if [ ! -d "$WORKFLOW_DIR" ]; then
  fail "$WORKFLOW_DIR directory does not exist"
fi

pass "$WORKFLOW_DIR directory exists"

if grep -R -n "local-dev-secret" "$WORKFLOW_DIR" >/tmp/workflow_secret_check_matches.txt 2>/dev/null; then
  cat /tmp/workflow_secret_check_matches.txt
  fail "local-dev-secret was found in exported workflow files"
fi

pass "local-dev-secret was not found"

if grep -R -n "POSTGRES_ADMIN_PASSWORD" "$WORKFLOW_DIR" >/tmp/workflow_secret_check_matches.txt 2>/dev/null; then
  cat /tmp/workflow_secret_check_matches.txt
  fail "POSTGRES_ADMIN_PASSWORD was found in exported workflow files"
fi

pass "POSTGRES_ADMIN_PASSWORD was not found"

if grep -R -n "POSTGRES_ADMIN_USER" "$WORKFLOW_DIR" >/tmp/workflow_secret_check_matches.txt 2>/dev/null; then
  cat /tmp/workflow_secret_check_matches.txt
  fail "POSTGRES_ADMIN_USER was found in exported workflow files"
fi

pass "POSTGRES_ADMIN_USER was not found"

if ! grep -R -n '\$env\.WEBHOOK_SECRET' "$WORKFLOW_DIR" >/tmp/workflow_secret_check_matches.txt 2>/dev/null; then
  fail "WEBHOOK_SECRET environment variable reference was not found"
fi

pass "WEBHOOK_SECRET environment variable reference found"

rm -f /tmp/workflow_secret_check_matches.txt

echo
pass "workflow secret checks completed successfully"
