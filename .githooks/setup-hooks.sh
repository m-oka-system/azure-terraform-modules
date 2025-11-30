#!/usr/bin/env bash

# Setup Git Hooks
# Run this script to install git hooks for all team members

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
HOOKS_DIR="$REPO_ROOT/.githooks"
GIT_HOOKS_DIR="$REPO_ROOT/.git/hooks"

echo "🔧 Setting up Git hooks..."
echo ""

# Install hooks from allowlist only to avoid executing untrusted files
APPROVED_HOOKS=("pre-commit")
for hook_name in "${APPROVED_HOOKS[@]}"; do
  src="$HOOKS_DIR/$hook_name"
  if [[ -f "$src" ]]; then
    echo "Installing $hook_name..."
    cp "$src" "$GIT_HOOKS_DIR/$hook_name"
    chmod +x "$GIT_HOOKS_DIR/$hook_name"
  else
    echo "Skipping $hook_name (not found in $HOOKS_DIR)"
  fi
done

echo ""
echo "✅ Git hooks installed successfully!"
echo ""
echo "Installed hooks:"
ls -lh "$GIT_HOOKS_DIR" | grep -v "sample" || true

echo ""
echo "💡 To uninstall, run: rm $GIT_HOOKS_DIR/pre-commit"
