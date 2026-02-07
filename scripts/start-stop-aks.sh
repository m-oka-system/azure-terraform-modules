#!/bin/bash
####################################
# AKS クラスター開始・停止スクリプト
####################################

set -euo pipefail

# デフォルト値
RESOURCE_GROUP=""
CLUSTER_NAME=""
ACTION=""
NO_WAIT=false

# 使用方法
usage() {
    cat <<EOF
使用方法: $(basename "$0") <start|stop> -g <resource-group> -n <cluster-name>

アクション:
  start                 AKSクラスターを開始
  stop                  AKSクラスターを停止

オプション:
  -g, --resource-group  リソースグループ名 (必須)
  -n, --name            AKSクラスター名 (必須)
  --no-wait             完了を待たずに非同期で実行
  -h, --help            このヘルプを表示

例:
  $(basename "$0") stop -g rg-terraform-dev -n aks-terraform-dev
  $(basename "$0") start -g rg-terraform-dev -n aks-terraform-dev
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
            CLUSTER_NAME="$2"
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

if [[ -z "$RESOURCE_GROUP" ]] || [[ -z "$CLUSTER_NAME" ]]; then
    echo "エラー: リソースグループ名とクラスター名は必須です" >&2
    usage
fi

# アクションに応じた表示設定
if [[ "$ACTION" == "start" ]]; then
    ACTION_LABEL="開始"
    EXPECTED_STATE="Running"
    ALREADY_MSG="クラスターは既に実行中です"
else
    ACTION_LABEL="停止"
    EXPECTED_STATE="Stopped"
    ALREADY_MSG="クラスターは既に停止しています"
fi

echo "=== AKS クラスター${ACTION_LABEL} ==="
echo "リソースグループ: $RESOURCE_GROUP"
echo "クラスター名: $CLUSTER_NAME"
echo ""

# クラスターの状態確認
echo "クラスターの状態を確認中..."
POWER_STATE=$(az aks show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CLUSTER_NAME" \
    --query "powerState.code" \
    --output tsv 2>/dev/null) || {
    echo "エラー: クラスターの状態を取得できませんでした" >&2
    exit 1
}

if [[ "$POWER_STATE" == "$EXPECTED_STATE" ]]; then
    echo "$ALREADY_MSG"
    exit 0
fi

echo "現在の状態: $POWER_STATE"
echo "クラスターを${ACTION_LABEL}しています..."

# AKSクラスター開始・停止
NO_WAIT_FLAG=()
if [[ "$NO_WAIT" == true ]]; then
    NO_WAIT_FLAG=(--no-wait)
fi

az aks "$ACTION" \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CLUSTER_NAME" \
    "${NO_WAIT_FLAG[@]}"

if [[ "$NO_WAIT" == true ]]; then
    echo "AKS クラスター '$CLUSTER_NAME' の${ACTION_LABEL}を要求しました (非同期)"
else
    echo "AKS クラスター '$CLUSTER_NAME' を${ACTION_LABEL}しました"
fi
