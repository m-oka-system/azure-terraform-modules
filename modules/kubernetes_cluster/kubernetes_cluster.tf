################################
# Kubernetes Cluster
################################
resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${var.common.project}-${var.common.env}"
  location            = var.common.location
  resource_group_name = var.resource_group_name
  sku_tier            = "Free"
  dns_prefix          = "aks-${var.common.project}-${var.common.env}"
  kubernetes_version  = "1.32"

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name                 = "default"
    type                 = "VirtualMachineScaleSets"
    node_count           = 1
    vm_size              = "Standard_D2s_v3"
    auto_scaling_enabled = true
    min_count            = 1
    max_count            = 3

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
    network_plugin      = "azure"             # ネットワークプラグインに Azure CNI を指定
    network_plugin_mode = "overlay"           # Azure CNI Overlay モードを有効化
    load_balancer_sku   = "standard"          # ロードバランサーの SKU
    outbound_type       = "managedNATGateway" # アウトバウンド通信にマネージド NAT Gateway を使用

    nat_gateway_profile {
      idle_timeout_in_minutes   = 4 # NAT Gateway のアイドルタイムアウト (分)
      managed_outbound_ip_count = 1 # 生成されるアウトバウンド用IPアドレス数
    }
  }

  tags = var.tags
}
