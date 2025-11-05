variable "common" {
  description = "共通設定（project, env, location など）"
  type = object({
    project  = string
    env      = string
    location = string
  })
}

variable "entra_external_id_app" {
  description = "Entra External ID アプリケーション登録の設定"
  type = map(object({
    name = string

    # サインインオーディエンス
    # - "AzureADandPersonalMicrosoftAccount": Azure AD アカウントと個人用 Microsoft アカウント
    # - "PersonalMicrosoftAccount": 個人用 Microsoft アカウントのみ
    # - "AzureADMyOrg": 単一テナント（このディレクトリのアカウントのみ）
    # - "AzureADMultipleOrgs": マルチテナント（任意の Azure AD ディレクトリ）
    sign_in_audience = string

    # Webアプリケーションのリダイレクト URI
    redirect_uris = list(string)

    # 暗黙的な許可フロー（Implicit Grant Flow）の設定
    implicit_grant = object({
      access_token_issuance_enabled = bool
      id_token_issuance_enabled     = bool
    })

    # SPA（Single Page Application）のリダイレクト URI（オプション）
    spa_redirect_uris = optional(list(string))

    # パブリッククライアント（モバイル/デスクトップアプリ）のリダイレクト URI（オプション）
    public_client_redirect_uris = optional(list(string))

    # アプリロールの割り当てが必要かどうか
    app_role_assignment_required = bool

    # クライアントシークレットを作成するかどうか
    # サーバーサイドアプリケーションの場合は true、SPA の場合は false
    create_client_secret = bool

    # クライアントシークレットの有効期限（例: "17520h" = 2年）
    client_secret_end_date_relative = string

    # 事前承認済みアプリケーションのクライアント ID リスト（オプション）
    pre_authorized_applications = optional(list(string))
  }))
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
