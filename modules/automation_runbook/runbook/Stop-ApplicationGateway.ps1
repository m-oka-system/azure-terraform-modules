####################################
# Application Gateway 停止 Runbook
####################################

try {
    # 実行開始をログに記録
    Write-Output "========================================="
    Write-Output "Application Gateway 停止処理を開始します"
    Write-Output "時刻: $((Get-Date).ToUniversalTime().AddHours(9).ToString('yyyy/MM/dd HH:mm:ss')) JST"
    Write-Output "========================================="

    # Automation 変数の取得
    Write-Output "Automation 変数を取得しています..."
    $resourceGroupName = Get-AutomationVariable -Name "ResourceGroupName"
    $appGatewayName = Get-AutomationVariable -Name "AppGatewayName"
    Write-Output "  リソースグループ: $resourceGroupName"
    Write-Output "  Application Gateway名: $appGatewayName"

    # Azure へのサインイン
    Write-Output "Azure にサインインしています..."
    Disable-AzContextAutosave -Scope Process | Out-Null
    Connect-AzAccount -Identity | Out-Null
    Write-Output "  Azure へのサインインが完了しました"

    # Application Gateway の状態確認
    Write-Output "Application Gateway の状態を確認しています..."
    $appGw = Get-AzApplicationGateway -ResourceGroupName $resourceGroupName -Name $appGatewayName
    $operationalState = $appGw.OperationalState
    Write-Output "  現在の状態: $operationalState"

    if ($operationalState -eq "Stopped") {
        Write-Output "  Application Gateway は既に停止しています。処理をスキップします"
    }
    else {
        # Application Gateway 停止
        Write-Output "Application Gateway を停止しています..."
        Stop-AzApplicationGateway -ApplicationGateway $appGw
        Write-Output "  Application Gateway の停止が完了しました"
    }

    # 実行完了をログに記録
    Write-Output "========================================="
    Write-Output "Application Gateway 停止処理が正常に完了しました"
    Write-Output "時刻: $((Get-Date).ToUniversalTime().AddHours(9).ToString('yyyy/MM/dd HH:mm:ss')) JST"
    Write-Output "========================================="
}
catch {
    Write-Error "Application Gateway 停止処理でエラーが発生しました: $_"
    throw
}
