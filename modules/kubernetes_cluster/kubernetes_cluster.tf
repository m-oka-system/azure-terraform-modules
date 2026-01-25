################################
# Kubernetes Cluster
################################
resource "azurerm_kubernetes_cluster" "this" {
  for_each                     = var.kubernetes_cluster
  name                         = "aks-${each.key}-${var.common.project}-${var.common.env}"
  location                     = var.common.location
  resource_group_name          = var.resource_group_name
  sku_tier                     = each.value.sku_tier
  dns_prefix                   = "aks-${each.key}-${var.common.project}-${var.common.env}"
  kubernetes_version           = each.value.kubernetes_version
  local_account_disabled       = each.value.local_account_disabled
  oidc_issuer_enabled          = each.value.oidc_issuer_enabled
  workload_identity_enabled    = each.value.workload_identity_enabled
  image_cleaner_enabled        = each.value.image_cleaner_enabled
  image_cleaner_interval_hours = each.value.image_cleaner_interval_hours

  # コントロールプレーン用のマネージド ID (ノードリソースグループをスコープとして共同作成者ロールが割り当てられる)
  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name                 = "default"
    type                 = "VirtualMachineScaleSets"
    node_count           = each.value.default_node_pool.node_count
    vm_size              = each.value.default_node_pool.vm_size
    auto_scaling_enabled = each.value.default_node_pool.auto_scaling_enabled
    min_count            = each.value.default_node_pool.min_count
    max_count            = each.value.default_node_pool.max_count
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
    load_balancer_sku   = "standard"     # ロードバランサーの SKU
    outbound_type       = "loadBalancer" # アウトバウンドのルーティング方式 (loadBalancer, userDefinedRouting, managedNATGateway, userAssignedNATGateway, none)
  }

  tags = var.tags
}
