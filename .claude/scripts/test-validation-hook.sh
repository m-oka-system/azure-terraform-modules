#!/usr/bin/env bash

# Test script for terraform-pre-commit-validation.sh
# Tests the validation hook and displays detailed error output

set -uo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo -e "${BLUE}Testing Terraform Pre-Commit Validation Hook${NC}"
echo "============================================="
echo ""
echo "Repository root: $PROJECT_ROOT"
echo "Validation script: $SCRIPT_DIR/terraform-pre-commit-validation.sh"
echo ""

# Check if validation script exists
if [[ ! -f "$SCRIPT_DIR/terraform-pre-commit-validation.sh" ]]; then
  echo -e "${RED}ERROR: Validation script not found${NC}"
  exit 1
fi

# Simulate Claude's tool input JSON
MOCK_INPUT='{
  "tool_name": "Bash",
  "tool_input": {
    "command": "git commit -m \"test commit\"",
    "description": "Create test commit"
  }
}'

echo -e "${YELLOW}Simulating git commit hook trigger...${NC}"
echo ""

# Create temp file for capturing output
OUTPUT_FILE=$(mktemp)
trap "rm -f $OUTPUT_FILE" EXIT

# Run validation script (disable set -e to capture exit code)
pushd "$PROJECT_ROOT" >/dev/null
set +e
echo "$MOCK_INPUT" | bash "$SCRIPT_DIR/terraform-pre-commit-validation.sh" 2>&1 | tee "$OUTPUT_FILE"
EXIT_CODE=${PIPESTATUS[1]}
set -e
popd >/dev/null

echo ""
echo "═══════════════════════════════════════════════════════"
echo -e "${BLUE}Test Results${NC}"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Exit code: $EXIT_CODE"
echo ""

case $EXIT_CODE in
  0)
    echo -e "${GREEN}✅ SUCCESS - All validations passed${NC}"
    ;;
  2)
    echo -e "${RED}❌ BLOCKING ERROR - Validation failed${NC}"
    echo ""
    echo -e "${YELLOW}Error details from validation output:${NC}"
    # Extract error lines (lines with ✗ or error indicators)
    grep -E "(✗|ERROR|failed|issue)" "$OUTPUT_FILE" 2>/dev/null || echo "  (No specific error messages captured)"
    echo ""
    echo -e "${YELLOW}💡 Tip: Review the validation output above for details${NC}"
    ;;
  *)
    echo -e "${YELLOW}⚠️  NON-BLOCKING ERROR - Code $EXIT_CODE${NC}"
    echo ""
    echo "Possible causes:"
    echo "  - Script execution error"
    echo "  - Missing dependencies (terraform, tflint, trivy)"
    echo "  - Permission issues"
    ;;
esac

echo ""
exit $EXIT_CODE
