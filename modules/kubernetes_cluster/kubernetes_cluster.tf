################################
# Kubernetes Cluster
################################
resource "azurerm_kubernetes_cluster" "this" {
  name                         = "aks-${var.common.project}-${var.common.env}"
  location                     = var.common.location
  resource_group_name          = var.resource_group_name
  sku_tier                     = var.kubernetes_cluster.sku_tier
  dns_prefix                   = "aks-${var.common.project}-${var.common.env}"
  kubernetes_version           = var.kubernetes_cluster.kubernetes_version
  local_account_disabled       = var.kubernetes_cluster.local_account_disabled
  oidc_issuer_enabled          = var.kubernetes_cluster.oidc_issuer_enabled
  workload_identity_enabled    = var.kubernetes_cluster.workload_identity_enabled
  image_cleaner_enabled        = var.kubernetes_cluster.image_cleaner_enabled
  image_cleaner_interval_hours = var.kubernetes_cluster.image_cleaner_interval_hours

  # コントロールプレーン用のマネージド ID (ノードリソースグループをスコープとして共同作成者ロールが割り当てられる)
  identity {
    type = "SystemAssigned"
  }

  api_server_access_profile {
    authorized_ip_ranges = var.allowed_cidr
  }

  default_node_pool {
    name                 = "default"
    type                 = "VirtualMachineScaleSets"
    vm_size              = var.kubernetes_cluster.default_node_pool.vm_size
    auto_scaling_enabled = var.kubernetes_cluster.default_node_pool.auto_scaling_enabled
    min_count            = var.kubernetes_cluster.default_node_pool.min_count
    max_count            = var.kubernetes_cluster.default_node_pool.max_count
    vnet_subnet_id       = var.vnet_subnet_id

    upgrade_settings {
      drain_timeout_in_minutes      = 0     # ドレインタイムアウト: ノードを停止する前に、実行中のPodを他のノードに移動させる最大待機時間（分）
      max_surge                     = "10%" # 最大サージ: アップグレード時に同時に作成できる追加ノードの割合
      node_soak_duration_in_minutes = 0     # ノード浸透時間: 新しいノードが作成されてから、次のノードのアップグレードを開始するまでの待機時間（分）
    }
  }

  workload_autoscaler_profile {
    keda_enabled                    = true # KEDA有効化: Kubernetes Event-driven Autoscaling（イベント駆動型自動スケーリング）
    vertical_pod_autoscaler_enabled = false
  }

  network_profile {
    network_plugin      = "azure"        # ネットワークプラグインに Azure CNI を指定
    network_plugin_mode = "overlay"      # Azure CNI Overlay モードを有効化
    network_policy      = "calico"       # ネットワークポリシーに Calico を指定
    load_balancer_sku   = "standard"     # ロードバランサーの SKU
    outbound_type       = "loadBalancer" # アウトバウンドのルーティング方式 (loadBalancer, userDefinedRouting, managedNATGateway, userAssignedNATGateway, none)
  }

  # Azure Key Vault シークレット ストア CSI ドライバー
  dynamic "key_vault_secrets_provider" {
    for_each = var.kubernetes_cluster.key_vault_secrets_provider != null ? [true] : []

    content {
      secret_rotation_enabled  = var.kubernetes_cluster.key_vault_secrets_provider.secret_rotation_enabled
      secret_rotation_interval = var.kubernetes_cluster.key_vault_secrets_provider.secret_rotation_interval
    }
  }

  tags = var.tags
}

# ノード (kubelet) がコンテナーイメージをプルできるようにする
resource "azurerm_role_assignment" "kubelet_identity" {
  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

# CSI Driver アドオン (Key Vault Secrets Provider) で作成されたマネージド ID を使用してシークレットを取得できるようにする
resource "azurerm_role_assignment" "key_vault_secrets_provider_identity" {
  count                = var.kubernetes_cluster.key_vault_secrets_provider != null ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].object_id
}
