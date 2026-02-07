#!/bin/bash
####################################
# Application Gateway 開始・停止スクリプト
####################################

set -euo pipefail

# デフォルト値
RESOURCE_GROUP=""
APPGW_NAME=""
ACTION=""
NO_WAIT=false

# 使用方法
usage() {
    cat <<EOF
使用方法: $(basename "$0") <start|stop> -g <resource-group> -n <appgw-name>

アクション:
  start                 Application Gatewayを開始
  stop                  Application Gatewayを停止

オプション:
  -g, --resource-group  リソースグループ名 (必須)
  -n, --name            Application Gateway名 (必須)
  --no-wait             完了を待たずに非同期で実行
  -h, --help            このヘルプを表示

例:
  $(basename "$0") stop -g rg-terraform-dev -n appgw-ingress-terraform-dev
  $(basename "$0") start -g rg-terraform-dev -n appgw-ingress-terraform-dev
EOF
    exit 1
}

# アクション引数の取得
if [[ $# -gt 0 ]] && [[ "$1" != -* ]]; then
    ACTION="$1"
    shift
fi

# 引数パース
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -n|--name)
            APPGW_NAME="$2"
            shift 2
            ;;
        --no-wait)
            NO_WAIT=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "エラー: 不明なオプション: $1" >&2
            usage
            ;;
    esac
done

# 必須パラメータチェック
if [[ -z "$ACTION" ]]; then
    echo "エラー: アクション (start|stop) は必須です" >&2
    usage
fi

if [[ "$ACTION" != "start" ]] && [[ "$ACTION" != "stop" ]]; then
    echo "エラー: アクションは start または stop を指定してください" >&2
    usage
fi

if [[ -z "$RESOURCE_GROUP" ]] || [[ -z "$APPGW_NAME" ]]; then
    echo "エラー: リソースグループ名とApplication Gateway名は必須です" >&2
    usage
fi

# アクションに応じた表示設定
if [[ "$ACTION" == "start" ]]; then
    ACTION_LABEL="開始"
    EXPECTED_STATE="Running"
    ALREADY_MSG="Application Gatewayは既に実行中です"
else
    ACTION_LABEL="停止"
    EXPECTED_STATE="Stopped"
    ALREADY_MSG="Application Gatewayは既に停止しています"
fi

echo "=== Application Gateway ${ACTION_LABEL} ==="
echo "リソースグループ: $RESOURCE_GROUP"
echo "Application Gateway名: $APPGW_NAME"
echo ""

# Application Gatewayの状態確認
echo "Application Gatewayの状態を確認中..."
OPERATIONAL_STATE=$(az network application-gateway show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APPGW_NAME" \
    --query "operationalState" \
    --output tsv 2>/dev/null) || {
    echo "エラー: Application Gatewayの状態を取得できませんでした" >&2
    exit 1
}

if [[ "$OPERATIONAL_STATE" == "$EXPECTED_STATE" ]]; then
    echo "$ALREADY_MSG"
    exit 0
fi

echo "現在の状態: $OPERATIONAL_STATE"
echo "Application Gatewayを${ACTION_LABEL}しています..."

# Application Gateway開始・停止
NO_WAIT_FLAG=()
if [[ "$NO_WAIT" == true ]]; then
    NO_WAIT_FLAG=(--no-wait)
fi

az network application-gateway "$ACTION" \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APPGW_NAME" \
    "${NO_WAIT_FLAG[@]}"

if [[ "$NO_WAIT" == true ]]; then
    echo "Application Gateway '$APPGW_NAME' の${ACTION_LABEL}を要求しました (非同期)"
else
    echo "Application Gateway '$APPGW_NAME' を${ACTION_LABEL}しました"
fi
