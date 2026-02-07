####################################
# Application Gateway 開始 Runbook
####################################

try {
    # 実行開始をログに記録
    Write-Output "========================================="
    Write-Output "Application Gateway 開始処理を開始します"
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

    if ($operationalState -eq "Running") {
        Write-Output "  Application Gateway は既に実行中です。処理をスキップします"
    }
    else {
        # Application Gateway 開始
        Write-Output "Application Gateway を開始しています..."
        Start-AzApplicationGateway -ApplicationGateway $appGw
        Write-Output "  Application Gateway の開始が完了しました"
    }

    # 実行完了をログに記録
    Write-Output "========================================="
    Write-Output "Application Gateway 開始処理が正常に完了しました"
    Write-Output "時刻: $((Get-Date).ToUniversalTime().AddHours(9).ToString('yyyy/MM/dd HH:mm:ss')) JST"
    Write-Output "========================================="
}
catch {
    Write-Error "Application Gateway 開始処理でエラーが発生しました: $_"
    throw
}
