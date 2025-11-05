################################
# Outputs
################################

# アプリケーション登録情報
output "application" {
  description = "Entra External ID アプリケーション登録の情報"
  value = {
    for k, v in azuread_application.this : k => {
      id           = v.id
      client_id    = v.client_id
      object_id    = v.object_id
      display_name = v.display_name
    }
  }
}

# サービスプリンシパル情報
output "service_principal" {
  description = "サービスプリンシパルの情報"
  value = {
    for k, v in azuread_service_principal.this : k => {
      id          = v.id
      object_id   = v.object_id
      client_id   = v.client_id
      app_role_id = v.app_role_ids
    }
  }
}

# クライアントシークレット情報（機密情報）
output "client_secret" {
  description = "クライアントシークレット（機密情報）"
  value = {
    for k, v in azuread_application_password.this : k => {
      key_id = v.key_id
      value  = v.value
    }
  }
  sensitive = true
}

# 認証エンドポイント情報
output "auth_endpoints" {
  description = "認証に使用するエンドポイント情報"
  value = {
    for k, v in azuread_application.this : k => {
      # 認証エンドポイント（テナントIDは環境に応じて置き換える必要があります）
      authority_url = "https://login.microsoftonline.com/common"

      # トークンエンドポイント
      token_endpoint = "https://login.microsoftonline.com/common/oauth2/v2.0/token"

      # 認可エンドポイント
      authorization_endpoint = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize"

      # OpenID Connect メタデータエンドポイント
      openid_config_endpoint = "https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration"
    }
  }
}

# アプリケーションのクライアントIDマップ（他のリソースから参照しやすいように）
output "client_ids" {
  description = "アプリケーションのクライアントIDマップ"
  value = {
    for k, v in azuread_application.this : k => v.client_id
  }
}

# アプリケーションのオブジェクトIDマップ
output "object_ids" {
  description = "アプリケーションのオブジェクトIDマップ"
  value = {
    for k, v in azuread_application.this : k => v.object_id
  }
}
