# Entra External ID Application Registration Module

このモジュールは、Microsoft Entra External ID（旧 Azure AD B2C の後継）を使用して、Webアプリケーションにサインイン・サインアップ機能を追加するためのアプリケーション登録を作成します。

## 機能

- アプリケーション登録の作成
- サービスプリンシパルの作成
- OAuth 2.0 / OpenID Connect による認証設定
- クライアントシークレットの生成（オプション）
- 必要な API 権限の自動設定
- Web、SPA、パブリッククライアント（モバイル/デスクトップ）のサポート

## 前提条件

- Azure AD テナント（Entra ID テナント）
- Terraform に AzureAD プロバイダーが設定されていること

```hcl
terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azuread" {
  # テナントID、クライアントID、クライアントシークレットなどの認証情報を設定
}
```

## 使用例

### 基本的な Web アプリケーション

```hcl
module "entra_external_id_app" {
  source = "./modules/entra_external_id_app"

  common = {
    project  = "myproject"
    env      = "dev"
    location = "japaneast"
  }

  entra_external_id_app = {
    webapp = {
      name = "webapp"

      # 外部ユーザー（個人アカウント含む）を許可
      sign_in_audience = "AzureADandPersonalMicrosoftAccount"

      # サインイン後のリダイレクト URI
      redirect_uris = [
        "https://your-app.azurewebsites.net/signin-oidc",
        "https://localhost:5001/signin-oidc"
      ]

      # 暗黙的な許可フローの設定
      implicit_grant = {
        access_token_issuance_enabled = false
        id_token_issuance_enabled     = true
      }

      # サーバーサイドアプリケーションのため、クライアントシークレットを作成
      create_client_secret            = true
      client_secret_end_date_relative = "17520h" # 2年

      app_role_assignment_required = false
    }
  }

  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}
```

### SPA（Single Page Application）の場合

```hcl
module "entra_external_id_app" {
  source = "./modules/entra_external_id_app"

  common = {
    project  = "myproject"
    env      = "prod"
    location = "japaneast"
  }

  entra_external_id_app = {
    spa = {
      name = "spa-app"

      sign_in_audience = "AzureADandPersonalMicrosoftAccount"

      # Web用リダイレクトURI
      redirect_uris = []

      # SPA用リダイレクトURI
      spa_redirect_uris = [
        "https://your-spa-app.azurewebsites.net",
        "http://localhost:3000"
      ]

      # 暗黙的な許可フロー（SPAでは推奨されない）
      implicit_grant = {
        access_token_issuance_enabled = false
        id_token_issuance_enabled     = false
      }

      # SPAではクライアントシークレットは使用しない
      create_client_secret            = false
      client_secret_end_date_relative = "17520h"

      app_role_assignment_required = false
    }
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### モバイルアプリケーションの場合

```hcl
module "entra_external_id_app" {
  source = "./modules/entra_external_id_app"

  common = {
    project  = "myproject"
    env      = "prod"
    location = "japaneast"
  }

  entra_external_id_app = {
    mobile = {
      name = "mobile-app"

      sign_in_audience = "AzureADandPersonalMicrosoftAccount"

      redirect_uris = []

      # パブリッククライアント（モバイル/デスクトップ）用リダイレクトURI
      public_client_redirect_uris = [
        "msauth://com.yourcompany.yourapp/callback",
        "urn:ietf:wg:oauth:2.0:oob"
      ]

      implicit_grant = {
        access_token_issuance_enabled = false
        id_token_issuance_enabled     = false
      }

      create_client_secret            = false
      client_secret_end_date_relative = "17520h"

      app_role_assignment_required = false
    }
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## 出力の使用方法

モジュールは以下の情報を出力します：

```hcl
# クライアントIDの取得
output "app_client_id" {
  value = module.entra_external_id_app.client_ids["webapp"]
}

# クライアントシークレットの取得（機密情報）
output "app_client_secret" {
  value     = module.entra_external_id_app.client_secret["webapp"].value
  sensitive = true
}

# 認証エンドポイントの取得
output "auth_endpoints" {
  value = module.entra_external_id_app.auth_endpoints["webapp"]
}
```

## アプリケーションでの設定例

### ASP.NET Core での設定

`appsettings.json`:

```json
{
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "TenantId": "common",
    "ClientId": "<output from module.entra_external_id_app.client_ids>",
    "ClientSecret": "<output from module.entra_external_id_app.client_secret>",
    "CallbackPath": "/signin-oidc"
  }
}
```

`Program.cs`:

```csharp
builder.Services.AddAuthentication(OpenIdConnectDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApp(builder.Configuration.GetSection("AzureAd"));
```

### React (MSAL.js) での設定

```javascript
import { PublicClientApplication } from "@azure/msal-browser";

const msalConfig = {
  auth: {
    clientId: "<output from module.entra_external_id_app.client_ids>",
    authority: "https://login.microsoftonline.com/common",
    redirectUri: "http://localhost:3000",
  },
};

const msalInstance = new PublicClientApplication(msalConfig);

// サインイン
await msalInstance.loginPopup({
  scopes: ["openid", "profile", "email"]
});
```

## 重要な注意事項

1. **テナントの選択**: `sign_in_audience` の設定により、どのユーザーがサインインできるかが決まります
   - `AzureADandPersonalMicrosoftAccount`: Azure AD と個人用 Microsoft アカウントの両方
   - `PersonalMicrosoftAccount`: 個人用 Microsoft アカウントのみ
   - `AzureADMyOrg`: 単一テナント（このディレクトリのアカウントのみ）

2. **クライアントシークレット**: サーバーサイドアプリケーションでのみ使用してください。SPAやモバイルアプリでは使用しないでください。

3. **リダイレクトURI**: アプリケーションの種類に応じて適切なリダイレクトURIを設定してください
   - Web: `redirect_uris`
   - SPA: `spa_redirect_uris`
   - モバイル/デスクトップ: `public_client_redirect_uris`

4. **API 権限**: このモジュールは基本的な OpenID Connect 権限（openid, profile, email, offline_access）を自動的に設定します。

5. **管理者の同意**: 初回のデプロイ後、Azure Portal で管理者の同意を実行する必要がある場合があります。

## 参考リンク

- [Microsoft Entra External ID ドキュメント](https://learn.microsoft.com/ja-jp/entra/external-id/)
- [MSAL.js ドキュメント](https://github.com/AzureAD/microsoft-authentication-library-for-js)
- [Microsoft Identity Platform ドキュメント](https://learn.microsoft.com/ja-jp/entra/identity-platform/)
