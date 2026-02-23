#!/usr/bin/env bash
# PostToolUse hook: Edit/Write 後にファイルを自動フォーマットする
# - *.tf  → terraform fmt
# - *.md  → prettier@2.8.8

set -euo pipefail

# 依存コマンドチェック
if ! command -v jq >/dev/null 2>&1; then
  echo "[auto-format] WARNING: jq が見つかりません。自動フォーマットをスキップします" >&2
  exit 0
fi

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || {
  exit 0
}

if [[ -z "$file_path" || ! -f "$file_path" ]]; then
  exit 0
fi

case "$file_path" in
  *.tf)
    if command -v terraform >/dev/null 2>&1; then
      if ! terraform fmt "$file_path" >/dev/null 2>/tmp/auto-format-err.log; then
        echo "[auto-format] WARNING: terraform fmt failed for $file_path" >&2
        cat /tmp/auto-format-err.log >&2
      fi
      rm -f /tmp/auto-format-err.log
    fi
    ;;
  *.md)
    if command -v npx >/dev/null 2>&1; then
      if ! npx --yes prettier@2.8.8 --write "$file_path" >/dev/null 2>/tmp/auto-format-err.log; then
        echo "[auto-format] WARNING: prettier failed for $file_path" >&2
        cat /tmp/auto-format-err.log >&2
      fi
      rm -f /tmp/auto-format-err.log
    fi
    ;;
esac

exit 0
