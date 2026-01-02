# Terraform Tests for Dev Environment

このディレクトリには、dev 環境の Terraform 構成をテストするためのテストファイルが含まれています。

## テストアプローチ

このテストスイートは **実際の dev 環境設定** をテストします：

- `dev/variables.tf` のデフォルト値を使用
- `dev/terraform.tfvars` の値を使用
- 実際にデプロイされる構成を検証

必要に応じて、特定のテストケースで variables ブロックを使用して設定を上書きできます。

## テストファイル

### `storage.tftest.hcl`
Azure Storage モジュールの包括的なテストスイート。以下のシナリオをカバーしています：

1. **dev 環境のデフォルト設定** - variables.tf で定義されている実際の構成をテスト
2. **app ストレージアカウント詳細** - セキュリティとデータ保護設定の確認
3. **web ストレージアカウント** - Static Website 機能とパブリックアクセスの確認
4. **func ストレージアカウント** - Azure Functions 用設定の確認
5. **ストレージ命名規則** - 命名規則の妥当性検証
6. **Blob コンテナ設定** - デフォルトコンテナの確認
7. **ストレージ管理ポリシー** - ライフサイクル管理ポリシーの確認
8. **セキュリティベストプラクティス** - 全アカウントのセキュリティ設定検証
9. **MyIP プレースホルダー** - terraform.tfvars の値への置換確認
10. **カスタム設定上書き** - 特定シナリオでの設定カスタマイズ検証

## テストの実行方法

### 前提条件

- Terraform v1.6.0 以降
- Azure プロバイダーの設定（認証情報）

### すべてのテストを実行

```bash
cd envs/dev
terraform init
terraform test
```

### 特定のテストファイルのみ実行

```bash
terraform test -filter=tests/storage.tftest.hcl
```

### 特定のテストケースのみ実行

```bash
terraform test -filter=tests/storage.tftest.hcl -run=basic_storage_account_plan
```

### 詳細な出力で実行

```bash
terraform test -verbose
```

## テストの種類

### Plan テスト（デフォルト）
実際のリソースを作成せずに、Terraform の計画段階で検証を行います。
- **コスト**: 無料
- **実行時間**: 高速
- **用途**: 設定の妥当性検証、デプロイ前の確認

### Apply テスト
実際に Azure リソースを作成して検証を行います。
- **コスト**: リソース作成費用が発生
- **実行時間**: 低速
- **用途**: 統合テスト、E2E テスト

**注意**: 現在のテストはすべて `command = plan` を使用しているため、実際のリソースは作成されません。

## 変数の扱い

### デフォルト値の使用

テストで variables ブロックを省略すると、自動的に以下が使用されます：

1. `dev/variables.tf` のデフォルト値
2. `dev/terraform.tfvars` の値
3. 環境変数

```hcl
# dev 環境の実際の設定をテスト
run "default_dev_configuration" {
  command = plan

  # variables ブロックなし → dev の実際の設定を使用

  assert {
    condition     = length(azurerm_storage_account.this) == 3
    error_message = "デフォルトでは3つのストレージアカウントが作成される"
  }
}
```

### 特定の設定を上書き

必要に応じて、variables ブロックで特定の値のみ上書きできます：

```hcl
run "custom_configuration" {
  command = plan

  variables {
    # 一部のみ上書き、残りは dev のデフォルト値を使用
    storage = {
      test = {
        name = "test"
        # ... カスタム設定
      }
    }
  }

  assert {
    # カスタム設定のテスト
  }
}
```

## テスト結果の読み方

### 成功時

```
Success! 10 passed, 0 failed.
```

### 失敗時

```
Failure! 9 passed, 1 failed.

run "basic_storage_account_plan"

  × assert {
    │ condition     = azurerm_storage_account.this["basic"].public_network_access_enabled == false
    │ error_message = "パブリックネットワークアクセスは無効にすべきです"
    }

    パブリックネットワークアクセスは無効にすべきです
```

## ベストプラクティス

1. **定期的な実行**: CI/CD パイプラインに組み込んで自動実行
2. **変更前のテスト**: モジュールを変更する前にテストを実行して現状を確認
3. **新規テストの追加**: 新しい機能を追加したら対応するテストも追加
4. **失敗テストの分析**: テスト失敗時は、設定の問題かテストの問題かを判断

## トラブルシューティング

### テストが実行できない

```bash
# Terraform のバージョンを確認
terraform version

# 必要なプロバイダーをインストール
terraform init
```

### アサーションエラー

テストのアサーションが失敗する場合は、以下を確認してください：

1. 変数の値が正しく設定されているか
2. モジュールのロジックが想定通りか
3. Azure リソースの制約条件を満たしているか

### Azure 認証エラー

テスト実行に Azure 認証は不要です（plan テストの場合）。
ただし、provider ブロックの設定は必要です。

## 参考資料

- [Terraform Tests Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [Azure Storage Account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account)
- [Azure Security Best Practices](https://learn.microsoft.com/azure/storage/common/security-recommendations)
