#!/usr/bin/env bash

# Setup Git Hooks
# Run this script to install git hooks for all team members

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
HOOKS_DIR="$REPO_ROOT/.githooks"
GIT_HOOKS_DIR="$REPO_ROOT/.git/hooks"

echo "🔧 Setting up Git hooks..."
echo ""

# Install hooks
for hook in "$HOOKS_DIR"/*; do
  if [[ -f "$hook" ]] && [[ "$hook" != *.sh ]] && [[ "$hook" != *.md ]]; then
    hook_name=$(basename "$hook")

    echo "Installing $hook_name..."
    cp "$hook" "$GIT_HOOKS_DIR/$hook_name"
    chmod +x "$GIT_HOOKS_DIR/$hook_name"
  fi
done

echo ""
echo "✅ Git hooks installed successfully!"
echo ""
echo "Installed hooks:"
ls -lh "$GIT_HOOKS_DIR" | grep -v "sample" || true

echo ""
echo "💡 To uninstall, run: rm $GIT_HOOKS_DIR/pre-commit"
