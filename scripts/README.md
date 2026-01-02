# Scripts

このディレクトリには、プロジェクト管理用のユーティリティスクリプトが含まれています。

## verify-security-headers.sh

Azure Front Door のエンドポイントに対して、セキュリティヘッダーが正しく設定されているかを検証するスクリプトです。

### 検証内容

- HTTP ステータスコード 200
- `Strict-Transport-Security` ヘッダーの存在
- `X-Frame-Options` ヘッダーの存在
- `X-Content-Type-Options` ヘッダーの存在
- `Referrer-Policy` ヘッダーの存在

### 使用方法

#### 方法1: 環境変数で設定（推奨）

```bash
export DNS_ZONE="example.com"
export ENV="dev"
./scripts/verify-security-headers.sh
```

#### 方法2: スクリプト内で直接設定

スクリプトを編集して、設定セクションのコメントを外して値を設定：

```bash
# scripts/verify-security-headers.sh の設定セクション
DNS_ZONE="example.com"
ENV="dev"
```

その後、スクリプトを実行：

```bash
./scripts/verify-security-headers.sh
```

#### 方法3: URL を直接指定

```bash
./scripts/verify-security-headers.sh https://api.example.com https://www.example.com
```

**方法1または2を使用した場合、以下の URL が自動的に生成されます：**
- `https://api-${ENV}.${DNS_ZONE}`
- `https://www-${ENV}.${DNS_ZONE}`
- `https://static-${ENV}.${DNS_ZONE}`

### 実行例

```bash
# 環境変数を設定
export DNS_ZONE="contoso.com"
export ENV="dev"

# スクリプトを実行
./scripts/verify-security-headers.sh
```

**出力例:**

```
環境変数から URL を構築します:
  DNS_ZONE: contoso.com
  ENV: dev
検証対象 URL:
  - https://api-dev.contoso.com
  - https://www-dev.contoso.com
  - https://static-dev.contoso.com

═══════════════════════════════════════════════════
  セキュリティヘッダー検証
═══════════════════════════════════════════════════

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
チェック対象: https://api-dev.contoso.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ ステータスコード: 200
✓ Strict-Transport-Security: max-age=31536000; includeSubDomains
✓ X-Frame-Options: DENY
✓ X-Content-Type-Options: nosniff
✓ Referrer-Policy: strict-origin-when-cross-origin
✓ すべてのチェックが成功しました

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
検証結果サマリー
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
総チェック数: 15
成功: 15
失敗: 0

✓ すべての URL で検証が成功しました
```

### 終了コード

| コード | 意味 |
|--------|------|
| 0 | すべてのチェックが成功 |
| 1 | 引数エラー |
| 2 | いずれかのチェックが失敗 |

### CI/CD での使用

GitHub Actions などの CI/CD パイプラインで使用する場合：

```yaml
- name: Verify Security Headers
  env:
    DNS_ZONE: ${{ secrets.DNS_ZONE }}
    ENV: dev
  run: |
    ./scripts/verify-security-headers.sh
```

### カスタマイズ

検証対象のサブドメインを変更する場合は、スクリプト内の `SUBDOMAIN_PREFIXES` 配列を編集してください：

```bash
SUBDOMAIN_PREFIXES=(
  "api"
  "www"
  "static"
  # 追加のサブドメインをここに追加
)
```

## gh-secret-variable-set.sh

GitHub Actions の Secrets と Variables を環境ごとに一括登録するスクリプトです。

### 概要

GitHub リポジトリの環境（dev, stg, prod など）に対して、Secrets（機密情報）と Variables（設定値）を一括で登録します。

### 必要なファイル

スクリプトと同じディレクトリに以下のファイルが必要です：

#### `.secrets`
機密情報を格納するファイル（**Gitにコミットしないこと**）

```bash
# Azure 認証情報
AZURE_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_SUBSCRIPTION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# その他の機密情報
ALLOWED_CIDR=xxx.xxx.xxx.xxx
VM_ADMIN_PASSWORD=your-secure-password
```

#### `variables`
非機密の設定値を格納するファイル

```bash
# ツールバージョン
TF_VERSION=1.13.4
TFLINT_VERSION=v0.59.1
TRIVY_VERSION=v0.67.2
```

### 使用方法

#### 事前準備

1. **GitHub CLI のインストールと認証**

```bash
# GitHub CLI がインストールされていない場合
brew install gh

# GitHub にログイン
gh auth login
```

2. **ファイルの準備**

```bash
cd scripts/

# .secrets ファイルを作成（サンプルをコピーして編集）
cp .secrets.example .secrets
vim .secrets  # 実際の値を設定

# variables ファイルは既に存在（必要に応じて編集）
vim variables
```

#### スクリプトの実行

```bash
# dev 環境に登録
./gh-secret-variable-set.sh dev

# stg 環境に登録
./gh-secret-variable-set.sh stg

# prod 環境に登録
./gh-secret-variable-set.sh prod

# 環境名を省略した場合は dev がデフォルト
./gh-secret-variable-set.sh
```

### 実行例

```bash
$ ./gh-secret-variable-set.sh dev
Environment: dev
Registering secrets for environment: dev
✓ Set Actions secret AZURE_CLIENT_ID for environment dev
✓ Set Actions secret AZURE_SUBSCRIPTION_ID for environment dev
✓ Set Actions secret AZURE_TENANT_ID for environment dev
✓ Set Actions secret ALLOWED_CIDR for environment dev
✓ Set Actions secret VM_ADMIN_PASSWORD for environment dev
Registering variables for environment: dev
✓ Set Actions variable TF_VERSION for environment dev
✓ Set Actions variable TFLINT_VERSION for environment dev
✓ Set Actions variable TRIVY_VERSION for environment dev
Successfully registered secrets and variables for dev environment
```

### セキュリティ上の注意

- **`.secrets` ファイルは絶対に Git にコミットしないでください**
- `.gitignore` に `.secrets` が含まれていることを確認してください
- Secrets は GitHub 上で暗号化されて保存されます
- Variables は暗号化されません（機密情報を含めないでください）

### トラブルシューティング

#### エラー: `.secrets file not found`

```bash
# .secrets ファイルが存在しない
# scripts/ ディレクトリ内で .secrets ファイルを作成してください
cd scripts/
touch .secrets
# 必要な Secrets を記述
```

#### エラー: `Not authenticated with GitHub CLI`

```bash
# GitHub CLI で認証していない
gh auth login
# 画面の指示に従って認証
```

#### エラー: `environment not found`

```bash
# 指定した環境が GitHub リポジトリに存在しない
# GitHub のリポジトリ設定で環境を作成してください
# Settings > Environments > New environment
```

### 関連コマンド

```bash
# 登録済みの Secrets を確認（値は表示されません）
gh secret list -e dev

# 登録済みの Variables を確認
gh variable list -e dev

# 特定の Secret を削除
gh secret delete SECRET_NAME -e dev

# 特定の Variable を削除
gh variable delete VARIABLE_NAME -e dev
```
