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

#### 方法 1: 環境変数で設定（推奨）

```bash
export DNS_ZONE="example.com"
export ENV="dev"
./scripts/verify-security-headers.sh
```

#### 方法 2: スクリプト内で直接設定

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

#### 方法 3: URL を直接指定

```bash
./scripts/verify-security-headers.sh https://api.example.com https://www.example.com
```

**方法 1 または 2 を使用した場合、以下の URL が自動的に生成されます：**

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

| コード | 意味                     |
| ------ | ------------------------ |
| 0      | すべてのチェックが成功   |
| 1      | 引数エラー               |
| 2      | いずれかのチェックが失敗 |

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

## gh-secret-set.sh / gh-variable-set.sh

GitHub Actions の Secrets と Variables を登録するスクリプトです。スコープ（Environment / Repository）を選択できます。

### スコープの違い

| スコープ    | オプション    | 参照元                              | 用途                            |
| ----------- | ------------- | ----------------------------------- | ------------------------------- |
| Environment | `-e <環境名>` | `environment:` を指定したジョブのみ | Secrets（認証情報等）           |
| Repository  | `-r`          | すべてのジョブ                      | Variables（ツールバージョン等） |

### 必要なファイル

スクリプトと同じディレクトリに以下のファイルが必要です。

#### `.secrets`

機密情報を格納するファイルです（**Git にコミットしないこと**）。

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

非機密の設定値を格納するファイルです。

```bash
# ツールバージョン
TF_VERSION=1.14.7
TFLINT_VERSION=v0.59.1
TRIVY_VERSION=v0.67.2
```

### 事前準備

```bash
# GitHub CLI のインストールと認証
brew install gh
gh auth login

# .secrets ファイルを作成
cd scripts/
cp .secrets.example .secrets
vim .secrets
```

### 使用方法

```bash
cd scripts/

# Secrets を Environment スコープで登録
./gh-secret-set.sh -e dev

# Variables を Repository スコープで登録（全ジョブから参照可能）
./gh-variable-set.sh -r

# Variables を Environment スコープで登録
./gh-variable-set.sh -e dev
```

### セキュリティ上の注意

- **`.secrets` ファイルは絶対に Git にコミットしないでください**
- `.gitignore` に `.secrets` が含まれていることを確認してください
- Secrets は GitHub 上で暗号化されて保存されます
- Variables は暗号化されません（機密情報を含めないでください）

### 関連コマンド

```bash
# 登録済みの確認
gh secret list -e dev
gh variable list -e dev
gh variable list

# 削除
gh secret delete SECRET_NAME -e dev
gh variable delete VARIABLE_NAME -e dev
gh variable delete VARIABLE_NAME
```
