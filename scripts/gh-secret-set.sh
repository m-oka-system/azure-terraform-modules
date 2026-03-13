#!/bin/bash
set -euo pipefail

# GitHub Actions Secrets 登録スクリプト
#
# 使用方法:
#   ./gh-secret-set.sh -e <環境名>    # Environment Secrets として登録
#   ./gh-secret-set.sh -r              # Repository Secrets として登録
#
# 例:
#   ./gh-secret-set.sh -e dev
#   ./gh-secret-set.sh -e prod
#   ./gh-secret-set.sh -r

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FILE=".secrets"
SCOPE=""
ENV=""

usage() {
  echo "Usage: $0 -e <環境名> | -r"
  echo "  -e <環境名>  Environment Secrets として登録"
  echo "  -r           Repository Secrets として登録"
  exit 1
}

while getopts "e:r" opt; do
  case "$opt" in
    e) SCOPE="environment"; ENV="$OPTARG" ;;
    r) SCOPE="repository" ;;
    *) usage ;;
  esac
done

[[ -z "$SCOPE" ]] && usage

# ファイルの存在チェック
if [[ ! -f "${SCRIPT_DIR}/${FILE}" ]]; then
  echo "Error: ${FILE} file not found in ${SCRIPT_DIR}"
  exit 1
fi

# GitHub CLI 認証状態チェック
if ! gh auth status &>/dev/null; then
  echo "Error: Not authenticated with GitHub CLI"
  echo "Please run 'gh auth login' first"
  exit 1
fi

# Secrets を登録
if [[ "$SCOPE" == "environment" ]]; then
  echo "Registering secrets for environment: ${ENV}"
  gh secret set -e "$ENV" -f "${SCRIPT_DIR}/${FILE}"
else
  echo "Registering repository secrets"
  gh secret set -f "${SCRIPT_DIR}/${FILE}"
fi

echo "Done."
