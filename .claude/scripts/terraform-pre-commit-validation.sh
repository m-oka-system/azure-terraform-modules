#!/usr/bin/env bash

# Terraform Pre-Commit Validation Hook
# Runs terraform validate, tflint, and trivy scan before git commits
# Validates each environment directory under envs/ (dev, stg, prod, etc.)

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse stdin JSON for tool information
TOOL_INPUT=$(cat)
TOOL_NAME=$(echo "$TOOL_INPUT" | jq -r '.tool_name // empty')
TOOL_COMMAND=$(echo "$TOOL_INPUT" | jq -r '.tool_input.command // empty')

# Only proceed if this is a Bash tool running git commit
if [[ "$TOOL_NAME" != "Bash" ]] || [[ "$TOOL_COMMAND" != *"git commit"* ]]; then
  exit 0  # Not a git commit, skip validation
fi

echo -e "${YELLOW}🔍 Pre-commit validation triggered${NC}"

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
ENVS_DIR="$PROJECT_DIR/envs"
VALIDATION_FAILED=0
TOOLS_SKIPPED=0

# Function to check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to find terraform files
has_terraform_files() {
  find "$PROJECT_DIR" -name "*.tf" -type f | grep -q .
}

# Exit early if no Terraform files
if ! has_terraform_files; then
  echo -e "${GREEN}✓ No Terraform files found, skipping validation${NC}"
  exit 0
fi

# Change to project directory
cd "$PROJECT_DIR"

# Find all environment directories under envs/
if [[ ! -d "$ENVS_DIR" ]]; then
  echo -e "${RED}✗ envs/ directory not found${NC}" >&2
  echo "  Expected directory structure: envs/dev, envs/stg, envs/prod, ..." >&2
  exit 2
fi

# Get list of environment directories
ENV_DIRS=($(find "$ENVS_DIR" -mindepth 1 -maxdepth 1 -type d | sort))

if [[ ${#ENV_DIRS[@]} -eq 0 ]]; then
  echo -e "${YELLOW}⚠ No environment directories found in envs/${NC}"
  exit 0
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Terraform Validation Pipeline"
echo "  Environments: ${ENV_DIRS[@]##*/}"
echo "═══════════════════════════════════════════════════════"
echo ""

# Validate each environment
for ENV_DIR in "${ENV_DIRS[@]}"; do
  ENV_NAME=$(basename "$ENV_DIR")

  echo -e "${BLUE}━━━ Environment: $ENV_NAME ━━━${NC}"
  echo ""

  # Check if environment has Terraform files
  if ! find "$ENV_DIR" -name "*.tf" -type f | grep -q .; then
    echo -e "${YELLOW}  ⚠ No .tf files in $ENV_NAME, skipping${NC}"
    echo ""
    continue
  fi

  cd "$ENV_DIR"

  # 1. Terraform Validate
  echo -e "${YELLOW}  [1/3] Running terraform validate in $ENV_NAME...${NC}"
  if command_exists terraform; then
    # Initialize if needed
    if [[ ! -d ".terraform" ]]; then
      echo "    → Initializing Terraform..."
      set +e
      INIT_OUTPUT=$(terraform init -backend=false 2>&1)
      INIT_EXIT=$?
      set -e
      if [[ $INIT_EXIT -ne 0 ]]; then
        echo -e "${RED}  ✗ Terraform init failed in $ENV_NAME${NC}" >&2
        echo "$INIT_OUTPUT" >&2
        VALIDATION_FAILED=1
      fi
    fi

    set +e
    VALIDATE_OUTPUT=$(terraform validate 2>&1)
    VALIDATE_EXIT=$?
    set -e

    if [[ $VALIDATE_EXIT -eq 0 ]]; then
      echo -e "${GREEN}  ✓ Terraform validate passed ($ENV_NAME)${NC}"
    else
      echo -e "${RED}  ✗ Terraform validate failed in $ENV_NAME${NC}" >&2
      echo "$VALIDATE_OUTPUT" >&2
      VALIDATION_FAILED=1
    fi
  else
    echo -e "${YELLOW}  ⚠ terraform not found, skipping${NC}"
    TOOLS_SKIPPED=$((TOOLS_SKIPPED + 1))
  fi

  echo ""

  # 2. TFLint
  echo -e "${YELLOW}  [2/3] Running tflint in $ENV_NAME...${NC}"
  if command_exists tflint; then
    # Use .tflint.hcl from envs/{env}/ if exists, otherwise from project root
    TFLINT_CONFIG=""
    if [[ -f "$ENV_DIR/.tflint.hcl" ]]; then
      TFLINT_CONFIG="--config=$ENV_DIR/.tflint.hcl"
    elif [[ -f "$PROJECT_DIR/.tflint.hcl" ]]; then
      TFLINT_CONFIG="--config=$PROJECT_DIR/.tflint.hcl"
    fi

    # Initialize tflint if needed
    if [[ ! -d ".tflint.d" ]]; then
      echo "    → Initializing tflint..."
      set +e
      TFLINT_INIT_OUTPUT=$(tflint --init $TFLINT_CONFIG 2>&1)
      TFLINT_INIT_EXIT=$?
      set -e
      if [[ $TFLINT_INIT_EXIT -ne 0 ]]; then
        echo -e "${YELLOW}  ⚠ tflint init failed, linting may be incomplete${NC}" >&2
        echo "    $TFLINT_INIT_OUTPUT" >&2
      fi
    fi

    set +e
    TFLINT_OUTPUT=$(tflint --format compact $TFLINT_CONFIG 2>&1)
    TFLINT_EXIT=$?
    set -e

    # tflint exit codes: 0=no issues, 2=errors found, 3=no files
    if [[ $TFLINT_EXIT -eq 0 ]] || [[ $TFLINT_EXIT -eq 3 ]]; then
      echo -e "${GREEN}  ✓ tflint passed ($ENV_NAME)${NC}"
    elif [[ -z "$TFLINT_OUTPUT" ]] || echo "$TFLINT_OUTPUT" | grep -q "0 issue(s)"; then
      echo -e "${GREEN}  ✓ tflint passed ($ENV_NAME)${NC}"
    else
      echo -e "${RED}  ✗ tflint found issues in $ENV_NAME:${NC}" >&2
      echo "$TFLINT_OUTPUT" >&2
      VALIDATION_FAILED=1
    fi
  else
    echo -e "${YELLOW}  ⚠ tflint not found, skipping${NC}"
    TOOLS_SKIPPED=$((TOOLS_SKIPPED + 1))
  fi

  echo ""

  # 3. Trivy Scan (per environment, CRITICAL and HIGH only)
  echo -e "${YELLOW}  [3/3] Running trivy config scan in $ENV_NAME (CRITICAL,HIGH only)...${NC}"
  if command_exists trivy; then
    # Scan for misconfigurations with severity filter
    # Execute in the environment directory for proper module resolution
    TRIVY_ERR_LOG=$(mktemp)
    set +e
    TRIVY_OUTPUT=$(trivy config . --severity CRITICAL,HIGH --format json 2>"$TRIVY_ERR_LOG")
    TRIVY_EXIT=$?
    set -e
    TRIVY_ERROR_MSG=$(cat "$TRIVY_ERR_LOG")
    rm -f "$TRIVY_ERR_LOG"

    if [[ $TRIVY_EXIT -gt 1 ]]; then
      echo -e "${RED}  ✗ trivy scan failed to run in $ENV_NAME${NC}" >&2
      [[ -n "$TRIVY_ERROR_MSG" ]] && echo "$TRIVY_ERROR_MSG" >&2
      VALIDATION_FAILED=1
    else
      # Check if there are any results (exit code 0=clean, 1=misconfig)
      # Validate JSON output before parsing
      if [[ -z "$TRIVY_OUTPUT" ]]; then
        echo -e "${YELLOW}  ⚠ trivy produced no output, treating as warning${NC}" >&2
        MISCONFIG_COUNT=0
      elif ! echo "$TRIVY_OUTPUT" | jq empty 2>/dev/null; then
        echo -e "${RED}  ✗ trivy output is not valid JSON in $ENV_NAME${NC}" >&2
        echo "    Raw output (first 500 chars): ${TRIVY_OUTPUT:0:500}" >&2
        VALIDATION_FAILED=1
        MISCONFIG_COUNT=-1
      else
        MISCONFIG_COUNT=$(echo "$TRIVY_OUTPUT" | jq '[.Results[]?.Misconfigurations // [] | length] | add // 0')
      fi

      if [[ "$MISCONFIG_COUNT" -eq -1 ]]; then
        # JSON parse error - already handled above, skip further processing
        :
      elif [[ "$MISCONFIG_COUNT" -eq 0 ]]; then
        echo -e "${GREEN}  ✓ trivy scan passed ($ENV_NAME)${NC}"
      else
        echo -e "${RED}  ✗ trivy found $MISCONFIG_COUNT security issue(s) in $ENV_NAME:${NC}" >&2
        # Show detailed table output (with logs to stderr)
        set +e
        trivy config . --severity CRITICAL,HIGH --format table >&2
        set -e
        VALIDATION_FAILED=1
      fi
    fi
  else
    echo -e "${YELLOW}  ⚠ trivy not found, skipping${NC}"
    echo "  Install: brew install trivy (macOS) or https://trivy.dev/latest/getting-started/installation/"
    TOOLS_SKIPPED=$((TOOLS_SKIPPED + 1))
  fi

  echo ""

  # Return to project root for next iteration
  cd "$PROJECT_DIR"
done

echo ""
echo "═══════════════════════════════════════════════════════"

# Final result
if [[ $VALIDATION_FAILED -eq 1 ]]; then
  echo -e "${RED}❌ Validation failed - review issues above${NC}" >&2
  echo "" >&2
  echo "💡 Tip: Fix the issues and commit again, or use --no-verify to skip validation" >&2
  exit 2  # Exit code 2 = blocking error for Claude
elif [[ $TOOLS_SKIPPED -ge 3 ]]; then
  echo -e "${YELLOW}⚠ All validation tools (terraform, tflint, trivy) are missing - no checks were performed${NC}" >&2
  echo "  Install the required tools before committing." >&2
  exit 2
else
  if [[ $TOOLS_SKIPPED -gt 0 ]]; then
    echo -e "${YELLOW}⚠ $TOOLS_SKIPPED of 3 validation tools were not found (checks were incomplete)${NC}"
  fi
  echo -e "${GREEN}✅ All validations passed successfully${NC}"
  exit 0
fi
