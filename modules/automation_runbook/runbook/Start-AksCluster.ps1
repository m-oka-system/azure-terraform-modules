####################################
# AKS クラスター起動 Runbook
####################################

try {
    # 実行開始をログに記録
    Write-Output "========================================="
    Write-Output "AKS クラスター起動処理を開始します"
    Write-Output "時刻: $((Get-Date).ToUniversalTime().AddHours(9).ToString('yyyy/MM/dd HH:mm:ss')) JST"
    Write-Output "========================================="

    # Automation 変数の取得
    Write-Output "Automation 変数を取得しています..."
    $resourceGroupName = Get-AutomationVariable -Name "ResourceGroupName"
    $aksClusterName = Get-AutomationVariable -Name "AksClusterName"
    Write-Output "  リソースグループ: $resourceGroupName"
    Write-Output "  クラスター名: $aksClusterName"

    # Azure へのサインイン
    Write-Output "Azure にサインインしています..."
    Disable-AzContextAutosave -Scope Process | Out-Null
    Connect-AzAccount -Identity | Out-Null
    Write-Output "  Azure へのサインインが完了しました"

    # クラスターの状態確認
    Write-Output "クラスターの状態を確認しています..."
    $cluster = Get-AzAksCluster -ResourceGroupName $resourceGroupName -Name $aksClusterName
    $powerState = $cluster.PowerState.Code
    Write-Output "  現在の状態: $powerState"

    if ($powerState -eq "Running") {
        Write-Output "  クラスターは既に実行中です。処理をスキップします"
    }
    else {
        # クラスター起動
        Write-Output "クラスターを起動しています..."
        Start-AzAksCluster -ResourceGroupName $resourceGroupName -Name $aksClusterName
        $cluster = Get-AzAksCluster -ResourceGroupName $resourceGroupName -Name $aksClusterName
        Write-Output "  クラスターの起動が完了しました"
        Write-Output "  起動後の状態: $($cluster.PowerState.Code)"
    }

    # 実行完了をログに記録
    Write-Output "========================================="
    Write-Output "AKS クラスター起動処理が正常に完了しました"
    Write-Output "時刻: $((Get-Date).ToUniversalTime().AddHours(9).ToString('yyyy/MM/dd HH:mm:ss')) JST"
    Write-Output "========================================="
}
catch {
    Write-Error "AKS クラスター起動処理でエラーが発生しました: $_"
    throw
}
