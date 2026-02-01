################################
# Kubernetes Cluster
################################
locals {
  # AGIC アドオンのマネージド ID に割り当てる組み込みロール
  agic_role_definition_names = ["Network Contributor", "Reader"]

  # Application Gateway
  application_gateway_public_ip_name = "ip-appgw-${var.common.project}-${var.common.env}"
  application_gateway_name           = "appgw-ingress-${var.common.project}-${var.common.env}"
  frontend_ip_configuration_name     = "appGatewayFrontendIP"
  backend_address_pool_name          = "bepool"
  backend_http_settings_name         = "settings"
  http_listener_name                 = "httpListener"
  http_request_routing_rule_name     = "rule1"
}

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

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
    vnet_subnet_id       = var.aks_subnet_id

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

  # Application Gateway イングレスコントローラー アドオン (AGIC)
  dynamic "ingress_application_gateway" {
    for_each = var.kubernetes_cluster.ingress_application_gateway != null ? [true] : []

    content {
      gateway_id = azurerm_application_gateway.this.id
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

# AGIC アドオンのマネージド ID を使用して Application Gateway を更新できるようにする
resource "azurerm_role_assignment" "ingress_application_gateway_identity" {
  for_each = toset(local.agic_role_definition_names)

  scope                = data.azurerm_resource_group.this.id
  role_definition_name = each.value
  principal_id         = azurerm_kubernetes_cluster.this.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}

# Application Gateway (AGIC)
resource "azurerm_public_ip" "this" {
  name                = local.application_gateway_public_ip_name
  resource_group_name = var.resource_group_name
  location            = var.common.location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = ["1", "2", "3"]

  tags = var.tags
}

resource "azurerm_application_gateway" "this" {
  name                              = local.application_gateway_name
  resource_group_name               = var.resource_group_name
  location                          = var.common.location
  enable_http2                      = true
  fips_enabled                      = false
  force_firewall_policy_association = false
  zones                             = ["1", "2", "3"]

  sku {
    name     = var.kubernetes_cluster.ingress_application_gateway.sku
    tier     = var.kubernetes_cluster.ingress_application_gateway.sku
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = var.appgw_subnet_id
  }

  frontend_ip_configuration {
    name                          = local.frontend_ip_configuration_name
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_port {
    name = "port_443"
    port = 443
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.backend_http_settings_name
    cookie_based_affinity = "Disabled"
    protocol              = "Http"
    port                  = 80
    request_timeout       = 20

    connection_draining {
      enabled           = true
      drain_timeout_sec = 60
    }
  }

  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "port_80"
    protocol                       = "Http"
    require_sni                    = false
  }

  request_routing_rule {
    name                       = local.http_request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.http_listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.backend_http_settings_name
    priority                   = 10010
  }

  lifecycle {
    # Ingress コントローラーにより管理されるため AGIC アドオン有効化後は無視する
    ignore_changes = [
      frontend_ip_configuration,
      frontend_port,
      backend_address_pool,
      backend_http_settings,
      http_listener,
      request_routing_rule,
      probe,
      tags,
    ]
  }

  tags = var.tags
}

# DNS A Record
resource "azurerm_dns_a_record" "appgw" {
  count               = var.dns_zone != null ? 1 : 0
  name                = "task-api"
  zone_name           = var.dns_zone.name
  resource_group_name = var.dns_zone.resource_group_name
  ttl                 = 3600
  records             = [azurerm_public_ip.this.ip_address]

  tags = var.tags
}
