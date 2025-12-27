# terraform-compliance ポリシー

このディレクトリには、Azure インフラストラクチャのセキュリティとコンプライアンスを検証するための terraform-compliance ポリシーが含まれています。

## 📁 ディレクトリ構造

```
compliance/
├── README.md                    # このファイル
├── Makefile                     # コマンドショートカット
├── features/
│   ├── security/               # セキュリティポリシー
│   │   ├── storage.feature     # Storage Account セキュリティ
│   │   ├── keyvault.feature    # Key Vault セキュリティ
│   │   ├── database.feature    # データベースセキュリティ
│   │   └── container.feature   # コンテナサービスセキュリティ
│   ├── network/                # ネットワークポリシー
│   │   └── network.feature     # NSG、VNet、Private Endpoint
│   ├── tagging/                # タグポリシー
│   │   └── tagging.feature     # 必須タグの検証
│   └── data-protection/        # データ保護ポリシー
│       └── data-protection.feature
└── steps/                      # カスタムステップ定義（将来の拡張用）
```

## 🚀 クイックスタート

### 方法 1: Makefile を使用（推奨）

```bash
cd compliance

# Plan を生成してテストを実行
make plan dev      # dev 環境の Plan を生成
make test dev      # dev 環境のテストを実行

# 他の環境
make plan stg      # stg 環境
make plan prod     # prod 環境

# ヘルプを表示
make help
```

### 方法 2: uvx で直接実行（インストール不要）

```bash
cd envs/dev

# プランを生成
terraform init
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# uvx で直接実行（自動でダウンロード・実行）
uvx terraform-compliance -f ../../compliance/features -p tfplan.json
```

### 方法 3: Docker を使用

```bash
docker run --rm \
  -v $(pwd):/target \
  eerkunt/terraform-compliance \
  -f /target/compliance/features \
  -p /target/envs/dev/tfplan.json
```

## 📋 Makefile コマンド一覧

```bash
# Plan 生成（環境名は必須）
make plan dev             # dev 環境の Plan を生成
make plan stg             # stg 環境の Plan を生成
make plan prod            # prod 環境の Plan を生成

# テスト実行
make test dev             # すべてのテストを実行
make test-critical dev    # クリティカルなテストのみ
make test-security dev    # セキュリティテストのみ
make test-network dev     # ネットワークテストのみ
make test-tagging dev     # タグテストのみ
make test-storage dev     # Storage 関連のみ
make test-keyvault dev    # Key Vault 関連のみ

# 一括実行
make ci dev               # Plan 生成 → テスト実行

# クリーンアップ
make clean dev            # 生成ファイルを削除
```

## 📋 ポリシー一覧

### セキュリティポリシー (`features/security/`)

| ファイル            | 検証内容                                                  |
| ------------------- | --------------------------------------------------------- |
| `storage.feature`   | Storage Account の HTTPS 強制、共有キー無効化、OAuth 認証 |
| `keyvault.feature`  | Key Vault のソフトデリート、RBAC 認証、ネットワーク ACL   |
| `database.feature`  | SQL/CosmosDB の TLS、Azure AD 認証、バックアップ          |
| `container.feature` | Container Registry の admin 無効化、Container Apps 設定   |

### ネットワークポリシー (`features/network/`)

| ファイル          | 検証内容                                      |
| ----------------- | --------------------------------------------- |
| `network.feature` | NSG 設定、VNet アドレス空間、Private Endpoint |

### タグポリシー (`features/tagging/`)

| ファイル          | 検証内容                           |
| ----------------- | ---------------------------------- |
| `tagging.feature` | 必須タグ（project, env）の存在確認 |

### データ保護ポリシー (`features/data-protection/`)

| ファイル                  | 検証内容                                           |
| ------------------------- | -------------------------------------------------- |
| `data-protection.feature` | 削除保持ポリシー、ソフトデリート、バックアップ設定 |

## 🏷️ タグの使用

シナリオにはタグが付いており、特定のテストグループのみを実行できます：

```bash
# クリティカルなセキュリティテストのみ
make test-critical dev

# または直接実行
uvx terraform-compliance -f features -p ../envs/dev/tfplan.json --tags @critical
```

### 利用可能なタグ

- `@critical` - 重要なセキュリティ要件
- `@storage` - Storage Account 関連
- `@keyvault` - Key Vault 関連
- `@database` - データベース関連
- `@network` - ネットワーク関連
- `@tagging` - タグ関連
- `@container` - コンテナサービス関連
- `@data-protection` - データ保護関連

## 🔧 CI/CD 統合

### GitHub Actions

```yaml
name: Terraform Compliance

on: [push, pull_request]

jobs:
  compliance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_wrapper: false

      - name: Install uv
        uses: astral-sh/setup-uv@v4

      - name: Terraform Init & Plan
        run: |
          terraform init -backend=false
          terraform plan -out=tfplan.binary
          terraform show -json tfplan.binary > tfplan.json
        working-directory: envs/dev

      - name: Run Compliance Tests
        run: uvx terraform-compliance -f compliance/features -p envs/dev/tfplan.json
```

詳細な例は `.github-actions-example.yml` を参照してください。

### Azure DevOps

```yaml
trigger:
  - main

pool:
  vmImage: "ubuntu-latest"

steps:
  - task: TerraformInstaller@1
    inputs:
      terraformVersion: "latest"

  - script: |
      curl -LsSf https://astral.sh/uv/install.sh | sh
      source $HOME/.local/bin/env
    displayName: "Install uv"

  - script: |
      cd envs/dev
      terraform init -backend=false
      terraform plan -out=tfplan.binary
      terraform show -json tfplan.binary > tfplan.json
    displayName: "Generate Terraform Plan"

  - script: |
      uvx terraform-compliance -f compliance/features -p envs/dev/tfplan.json
    displayName: "Run Compliance Tests"
```

## 📝 カスタムポリシーの追加

新しいポリシーを追加する場合：

1. 適切なディレクトリに `.feature` ファイルを作成
2. BDD (Gherkin) 構文でシナリオを記述
3. タグを付けて分類

### 例：新しいポリシーの追加

```gherkin
# features/security/my-custom-policy.feature
@custom @security
Feature: My Custom Security Policy
  カスタムセキュリティ要件を検証します

  @critical
  Scenario: リソース名は命名規則に従う
    Given I have azurerm_resource_group defined
    When its name is not null
    Then its name must match the "^rg-.*" regex
```

## 🔗 参考リンク

- [terraform-compliance 公式ドキュメント](https://terraform-compliance.com/)
- [Azure セキュリティベストプラクティス](https://learn.microsoft.com/azure/security/fundamentals/best-practices-and-patterns)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [uv (Python パッケージマネージャー)](https://docs.astral.sh/uv/)

## ⚠️ 注意事項

1. **環境名は必須**: `make plan dev` のように、環境名を指定する必要があります。

2. **スキップされるテスト**: リソースが Plan に含まれていない場合、そのテストはスキップされます（例: Cosmos DB が無効な場合）。

3. **dev 環境の例外**: 一部の設定（パージ保護など）は dev 環境では無効でも許容しています。本番環境では別のポリシーを検討してください。

4. **更新**: Azure のベストプラクティスは定期的に更新されるため、ポリシーも定期的に見直すことをお勧めします。
