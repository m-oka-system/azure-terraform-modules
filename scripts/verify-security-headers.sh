#!/bin/bash

################################################################################
# セキュリティヘッダー検証スクリプト
#
# 使用方法:
#   方法1: 環境変数で設定（推奨）
#     export DNS_ZONE="example.com"
#     export ENV="dev"
#     ./scripts/verify-security-headers.sh
#
#   方法2: URL を直接指定
#     ./scripts/verify-security-headers.sh <URL1> [URL2] [URL3] ...
#
# 例:
#   export DNS_ZONE="example.com"
#   export ENV="dev"
#   ./scripts/verify-security-headers.sh
#   # 以下の URL を自動生成して検証:
#   # - https://api-dev.example.com
#   # - https://www-dev.example.com
#   # - https://static-dev.example.com
#
# 検証内容:
#   - HTTP ステータスコード 200
#   - Strict-Transport-Security ヘッダー
#   - X-Frame-Options ヘッダー
#   - X-Content-Type-Options ヘッダー
#   - Referrer-Policy ヘッダー
#
# 終了コード:
#   0: すべてのチェックが成功
#   1: 引数エラー
#   2: いずれかのチェックが失敗
################################################################################

set -e

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# 設定
################################################################################
# DNS ゾーン名と環境名を設定
# 方法1: 環境変数として export（推奨）
#   export DNS_ZONE="example.com"
#   export ENV="dev"
#
# 方法2: スクリプト内で直接設定（以下のコメントを外して値を設定）
#   DNS_ZONE="example.com"
#   ENV="dev"
#
# 方法3: 環境変数が未設定の場合のデフォルト値（以下で設定）

# デフォルト値（環境変数が未設定の場合に使用）
: "${DNS_ZONE:=}"  # 空の場合は URL を直接指定する必要があります
: "${ENV:=}"       # 空の場合は URL を直接指定する必要があります

# 必須セキュリティヘッダー
REQUIRED_HEADERS=(
  "Strict-Transport-Security"
  "X-Frame-Options"
  "X-Content-Type-Options"
  "Referrer-Policy"
)

# Front Door カスタムドメインのサブドメインプレフィックス
# locals.tf の frontdoor_custom_domain_mapping に対応
SUBDOMAIN_PREFIXES=(
  "api"
  "www"
  "static"
)

################################################################################
# 引数チェックと URL 決定
################################################################################
URLS=()

# 環境変数が設定されている場合は、それを使用
if [ -n "${DNS_ZONE}" ] && [ -n "${ENV}" ]; then
  echo -e "${BLUE}環境変数から URL を構築します:${NC}"
  echo -e "  DNS_ZONE: ${DNS_ZONE}"
  echo -e "  ENV: ${ENV}"

  # URL を配列に格納（macOS 互換）
  for prefix in "${SUBDOMAIN_PREFIXES[@]}"; do
    URLS+=("https://${prefix}-${ENV}.${DNS_ZONE}")
  done

  echo -e "${BLUE}検証対象 URL:${NC}"
  for url in "${URLS[@]}"; do
    echo -e "  - ${url}"
  done
  echo ""

# 引数が指定されている場合は、それを使用
elif [ $# -gt 0 ]; then
  URLS=("$@")

# どちらも指定されていない場合はエラー
else
  echo -e "${RED}エラー: URL の指定方法が正しくありません${NC}"
  echo ""
  echo "使用方法:"
  echo "  方法1: 環境変数で設定"
  echo "    export DNS_ZONE=\"example.com\""
  echo "    export ENV=\"dev\""
  echo "    $0"
  echo ""
  echo "  方法2: URL を直接指定"
  echo "    $0 <URL1> [URL2] [URL3] ..."
  echo ""
  exit 1
fi

# グローバル変数
TOTAL_CHECKS=0
FAILED_CHECKS=0

################################################################################
# 関数: 単一 URL のセキュリティヘッダーをチェック
################################################################################
check_url() {
  local url=$1
  local url_failed=0

  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}チェック対象: ${url}${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  # HTTP リクエストを実行してヘッダーを取得
  local response
  response=$(curl -sI -w "\n%{http_code}" --max-time 10 "${url}" 2>&1) || {
    echo -e "${RED}✗ エラー: ${url} にアクセスできませんでした${NC}"
    echo -e "  詳細: ${response}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    return 1
  }

  # ステータスコードを抽出（最終行）
  local status_code
  status_code=$(echo "${response}" | tail -n 1)

  # レスポンスヘッダー（ステータスコード行を除く）
  # macOS 互換: sed で最後の行を削除
  local headers
  headers=$(echo "${response}" | sed '$d')

  # ステータスコード 200 チェック
  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  if [ "${status_code}" = "200" ]; then
    echo -e "${GREEN}✓ ステータスコード: 200${NC}"
  else
    echo -e "${RED}✗ ステータスコード: ${status_code} (期待値: 200)${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    url_failed=1
  fi

  # 各セキュリティヘッダーをチェック
  for header in "${REQUIRED_HEADERS[@]}"; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    # ヘッダーが存在するかチェック（大文字小文字を区別しない）
    if echo "${headers}" | grep -qi "^${header}:"; then
      local header_value
      header_value=$(echo "${headers}" | grep -i "^${header}:" | cut -d':' -f2- | xargs)
      echo -e "${GREEN}✓ ${header}: ${header_value}${NC}"
    else
      echo -e "${RED}✗ ${header}: ヘッダーが見つかりません${NC}"
      FAILED_CHECKS=$((FAILED_CHECKS + 1))
      url_failed=1
    fi
  done

  # URL ごとの結果サマリー
  if [ ${url_failed} -eq 0 ]; then
    echo -e "${GREEN}✓ すべてのチェックが成功しました${NC}"
  else
    echo -e "${RED}✗ いくつかのチェックが失敗しました${NC}"
  fi

  return ${url_failed}
}

################################################################################
# メイン処理
################################################################################
main() {
  echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}  セキュリティヘッダー検証${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"

  local all_passed=0

  # 各 URL に対してチェックを実行
  for url in "$@"; do
    check_url "${url}" || all_passed=1
  done

  # 最終結果サマリー
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}検証結果サマリー${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "総チェック数: ${TOTAL_CHECKS}"
  echo -e "成功: $((TOTAL_CHECKS - FAILED_CHECKS))"
  echo -e "失敗: ${FAILED_CHECKS}"
  echo ""

  if [ ${all_passed} -eq 0 ]; then
    echo -e "${GREEN}✓ すべての URL で検証が成功しました${NC}"
    exit 0
  else
    echo -e "${RED}✗ 一部の URL で検証が失敗しました${NC}"
    exit 2
  fi
}

# スクリプト実行
main "${URLS[@]}"
