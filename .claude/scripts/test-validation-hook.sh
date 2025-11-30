#!/usr/bin/env bash

# Test script for terraform-pre-commit-validation.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Testing Terraform Pre-Commit Validation Hook"
echo "============================================="
echo ""
echo "Repository root: $PROJECT_ROOT"
echo ""

# Simulate Claude's tool input JSON
MOCK_INPUT='{
  "tool_name": "Bash",
  "tool_input": {
    "command": "git commit -m \"test commit\"",
    "description": "Create test commit"
  }
}'

echo "Simulating git commit hook trigger..."
pushd "$PROJECT_ROOT" >/dev/null
echo "$MOCK_INPUT" | bash "$SCRIPT_DIR/terraform-pre-commit-validation.sh"
EXIT_CODE=$?
popd >/dev/null

echo ""
echo "Hook exit code: $EXIT_CODE"
echo ""

case $EXIT_CODE in
  0)
    echo "✅ Success - All validations passed"
    ;;
  2)
    echo "❌ Blocking error - Validation failed"
    ;;
  *)
    echo "⚠️  Non-blocking error - Code $EXIT_CODE"
    ;;
esac
