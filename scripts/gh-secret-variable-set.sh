#!/bin/bash
set -euo pipefail

# GitHub Actions Secrets/Variables 登録スクリプト
#
# 使用方法:
#   ./gh-secret-variable-set.sh [環境名]
#
# 例:
#   ./gh-secret-variable-set.sh dev
#   ./gh-secret-variable-set.sh stg
#   ./gh-secret-variable-set.sh prod

# 環境名を引数から取得（デフォルトは dev）
ENV="${1:-dev}"

echo "Environment: $ENV"

# 必要なファイルの存在チェック
if [[ ! -f ".secrets" ]]; then
  echo "Error: .secrets file not found in current directory"
  echo "Please create .secrets file with required secrets"
  exit 1
fi

if [[ ! -f "variables" ]]; then
  echo "Error: variables file not found in current directory"
  echo "Please create variables file with required variables"
  exit 1
fi

# GitHub CLI 認証状態チェック
if ! gh auth status &>/dev/null; then
  echo "Error: Not authenticated with GitHub CLI"
  echo "Please run 'gh auth login' first"
  exit 1
fi

# Secrets を登録
echo "Registering secrets for environment: $ENV"
gh secret set -e "$ENV" -f .secrets

# Variables を登録
echo "Registering variables for environment: $ENV"
gh variable set -e "$ENV" -f variables

echo "Successfully registered secrets and variables for $ENV environment"
