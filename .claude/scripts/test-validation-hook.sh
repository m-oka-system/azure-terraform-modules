#!/usr/bin/env bash

# Test script for terraform-post-commit-validation.sh

echo "Testing Terraform Post-Commit Validation Hook"
echo "=============================================="
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
echo "$MOCK_INPUT" | bash .claude/scripts/terraform-post-commit-validation.sh

EXIT_CODE=$?

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
