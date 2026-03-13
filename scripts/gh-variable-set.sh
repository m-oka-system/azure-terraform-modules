#!/bin/bash
set -euo pipefail

# GitHub Actions Variables 登録スクリプト
#
# 使用方法:
#   ./gh-variable-set.sh -e <環境名>    # Environment Variables として登録
#   ./gh-variable-set.sh -r              # Repository Variables として登録
#
# 例:
#   ./gh-variable-set.sh -e dev
#   ./gh-variable-set.sh -e prod
#   ./gh-variable-set.sh -r

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FILE="variables"
SCOPE=""
ENV=""

usage() {
  echo "Usage: $0 -e <環境名> | -r"
  echo "  -e <環境名>  Environment Variables として登録"
  echo "  -r           Repository Variables として登録"
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

# Variables を登録
if [[ "$SCOPE" == "environment" ]]; then
  echo "Registering variables for environment: ${ENV}"
  gh variable set -e "$ENV" -f "${SCRIPT_DIR}/${FILE}"
else
  echo "Registering repository variables"
  gh variable set -f "${SCRIPT_DIR}/${FILE}"
fi

echo "Done."
