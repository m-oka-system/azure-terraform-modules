################################
# Entra External ID Application Registration
################################

# アプリケーション登録
resource "azuread_application" "this" {
  for_each     = var.entra_external_id_app
  display_name = "app-${each.value.name}-${var.common.project}-${var.common.env}"

  # External ID（CIAM）用の設定
  # 外部ユーザー（個人アカウント）のサインインを許可
  sign_in_audience = each.value.sign_in_audience

  # Webアプリケーションの設定
  web {
    redirect_uris = each.value.redirect_uris

    # 暗黙的な許可フロー（SPAの場合に有効化）
    implicit_grant {
      access_token_issuance_enabled = each.value.implicit_grant.access_token_issuance_enabled
      id_token_issuance_enabled     = each.value.implicit_grant.id_token_issuance_enabled
    }
  }

  # SPA（Single Page Application）の設定（オプション）
  dynamic "single_page_application" {
    for_each = each.value.spa_redirect_uris != null ? [true] : []

    content {
      redirect_uris = each.value.spa_redirect_uris
    }
  }

  # パブリッククライアント（モバイル/デスクトップアプリ）の設定（オプション）
  dynamic "public_client" {
    for_each = each.value.public_client_redirect_uris != null ? [true] : []

    content {
      redirect_uris = each.value.public_client_redirect_uris
    }
  }

  # 必要なAPI権限
  # OpenID Connect用の基本的な権限
  required_resource_access {
    # Microsoft Graph API
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    # openid, profile, email, offline_access の権限
    resource_access {
      # openid
      id   = "37f7f235-527c-4136-accd-4a02d197296e"
      type = "Scope"
    }

    resource_access {
      # profile
      id   = "14dad69e-099b-42c9-810b-d002981feec1"
      type = "Scope"
    }

    resource_access {
      # email
      id   = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0"
      type = "Scope"
    }

    resource_access {
      # offline_access
      id   = "7427e0e9-2fba-42fe-b0c0-848c9e6a8182"
      type = "Scope"
    }
  }

  # オプションのクレーム設定
  optional_claims {
    access_token {
      name = "email"
    }

    id_token {
      name = "email"
    }
  }

  tags = var.tags
}

# サービスプリンシパルの作成
resource "azuread_service_principal" "this" {
  for_each                     = var.entra_external_id_app
  client_id                    = azuread_application.this[each.key].client_id
  app_role_assignment_required = each.value.app_role_assignment_required

  tags = var.tags
}

# クライアントシークレットの作成（オプション）
# サーバーサイドアプリケーションの場合に使用
resource "azuread_application_password" "this" {
  for_each = {
    for k, v in var.entra_external_id_app : k => v
    if v.create_client_secret
  }

  application_id = azuread_application.this[each.key].id
  display_name   = "client-secret-${each.key}"

  # シークレットの有効期限（デフォルト: 2年）
  end_date_relative = each.value.client_secret_end_date_relative
}

# 事前承認済みアプリケーション（オプション）
# 管理者の同意が不要になるように設定
resource "azuread_application_pre_authorized" "this" {
  for_each = {
    for item in flatten([
      for k, v in var.entra_external_id_app : [
        for app_id in v.pre_authorized_applications : {
          key    = "${k}-${app_id}"
          app_key = k
          app_id  = app_id
        }
      ] if v.pre_authorized_applications != null
    ]) : item.key => item
  }

  application_id       = azuread_application.this[each.value.app_key].id
  authorized_client_id = each.value.app_id

  permission_ids = [
    # すべてのスコープを事前承認
    "37f7f235-527c-4136-accd-4a02d197296e", # openid
    "14dad69e-099b-42c9-810b-d002981feec1", # profile
    "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0", # email
    "7427e0e9-2fba-42fe-b0c0-848c9e6a8182", # offline_access
  ]
}
