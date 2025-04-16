variable "common" {
  type = map(string)
  default = {
    project  = "terraform"
    env      = "dev"
    location = "japaneast"
  }
}

variable "allowed_cidr" {
  type    = string
  default = "203.0.113.10,203.0.113.11"
}

variable "vnet" {
  type = map(object({
    name          = string
    address_space = list(string)
  }))
  default = {
    spoke1 = {
      name          = "spoke1"
      address_space = ["10.10.0.0/16"]
    }
  }
}

variable "subnet" {
  type = map(object({
    name                              = string
    target_vnet                       = string
    address_prefixes                  = list(string)
    default_outbound_access_enabled   = bool
    private_endpoint_network_policies = string
    service_delegation = object({
      name    = string
      actions = list(string)
    })
  }))
  default = {
    pe = {
      name                              = "pe"
      target_vnet                       = "spoke1"
      address_prefixes                  = ["10.10.0.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Enabled"
      service_delegation                = null
    }
    app = {
      name                              = "app"
      target_vnet                       = "spoke1"
      address_prefixes                  = ["10.10.1.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
      service_delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    func = {
      name                              = "func"
      target_vnet                       = "spoke1"
      address_prefixes                  = ["10.10.2.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
      service_delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    db = {
      name                              = "db"
      target_vnet                       = "spoke1"
      address_prefixes                  = ["10.10.3.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
      service_delegation = {
        name    = "Microsoft.DBforMySQL/flexibleServers"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
    vm = {
      name                              = "vm"
      target_vnet                       = "spoke1"
      address_prefixes                  = ["10.10.4.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
      service_delegation                = null
    }
    bastion = {
      name                              = "AzureBastionSubnet"
      target_vnet                       = "spoke1"
      address_prefixes                  = ["10.10.5.0/24"]
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
      service_delegation                = null
    }
  }
}

variable "network_security_group" {
  type = map(object({
    name          = string
    target_subnet = string
  }))
  default = {
    pe = {
      name          = "pe"
      target_subnet = "pe"
    }
    app = {
      name          = "app"
      target_subnet = "app"
    }
    func = {
      name          = "func"
      target_subnet = "func"
    }
    db = {
      name          = "db"
      target_subnet = "db"
    }
    vm = {
      name          = "vm"
      target_subnet = "vm"
    }
    bastion = {
      name          = "bastion"
      target_subnet = "bastion"
    }
  }
}

variable "network_security_rule" {
  type = list(object({
    target_nsg                   = string
    name                         = string
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = optional(string)
    source_port_ranges           = optional(list(string))
    destination_port_range       = optional(string)
    destination_port_ranges      = optional(list(string))
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(list(string))
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
  }))

  # 単数・複数の排他的なパラメータはどちらか一方を指定する
  validation {
    condition = alltrue([
      for rule in var.network_security_rule :
      (rule.source_port_range != null && rule.source_port_ranges == null) ||
      (rule.source_port_range == null && rule.source_port_ranges != null)
    ])
    error_message = "送信元ポートは単数(source_port_range)または複数(source_port_ranges)のどちらか一方のみ指定してください。"
  }

  validation {
    condition = alltrue([
      for rule in var.network_security_rule :
      (rule.destination_port_range != null && rule.destination_port_ranges == null) ||
      (rule.destination_port_range == null && rule.destination_port_ranges != null)
    ])
    error_message = "宛先ポートは単数(destination_port_range)または複数(destination_port_ranges)のどちらか一方のみ指定してください。"
  }

  validation {
    condition = alltrue([
      for rule in var.network_security_rule :
      (rule.source_address_prefix != null && rule.source_address_prefixes == null) ||
      (rule.source_address_prefix == null && rule.source_address_prefixes != null)
    ])
    error_message = "送信元アドレスは単数(source_address_prefix)または複数(source_address_prefixes)のどちらか一方のみ指定してください。"
  }

  validation {
    condition = alltrue([
      for rule in var.network_security_rule :
      (rule.destination_address_prefix != null && rule.destination_address_prefixes == null) ||
      (rule.destination_address_prefix == null && rule.destination_address_prefixes != null)
    ])
    error_message = "宛先アドレスは単数(destination_address_prefix)または複数(destination_address_prefixes)のどちらか一方のみ指定してください。"
  }

  default = [
    # PE Subnet
    {
      target_nsg                 = "pe"
      name                       = "AllowAppSubnetHTTPSInbound"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "10.10.1.0/24"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "pe"
      name                       = "AllowFuncSubnetHTTPSInbound"
      priority                   = 1100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "10.10.2.0/24"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "pe"
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "pe"
      name                       = "DenyAllOutbound"
      priority                   = 4096
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    # App Subnet
    {
      target_nsg                 = "app"
      name                       = "AllowPeSubnetHTTPSOutbound"
      priority                   = 1000
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "10.10.0.0/24"
    },
    {
      target_nsg                 = "app"
      name                       = "AllowDbSubnetMySQLOutbound"
      priority                   = 1100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3306"
      source_address_prefix      = "*"
      destination_address_prefix = "10.10.3.0/24"
    },
    {
      target_nsg                 = "app"
      name                       = "AllowInternetOutbound"
      priority                   = 1200
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    },
    {
      target_nsg                 = "app"
      name                       = "DenyAllOutbound"
      priority                   = 4096
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    # Function Subnet
    {
      target_nsg                 = "func"
      name                       = "AllowPeSubnetHTTPSOutbound"
      priority                   = 1000
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "10.10.0.0/24"
    },
    {
      target_nsg                 = "func"
      name                       = "AllowInternetOutbound"
      priority                   = 1100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    },
    {
      target_nsg                 = "func"
      name                       = "DenyAllOutbound"
      priority                   = 4096
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    # DB Subnet
    {
      target_nsg                 = "db"
      name                       = "AllowAppSubnetMySQLInbound"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3306"
      source_address_prefix      = "10.10.1.0/24"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "db"
      name                       = "AllowVmSubnetMySQLInbound"
      priority                   = 1100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3306"
      source_address_prefix      = "10.10.4.0/24"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "db"
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "db"
      name                       = "DenyAllOutbound"
      priority                   = 4096
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    # VM Subnet
    {
      target_nsg                 = "vm"
      name                       = "AllowSshRdpInbound"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["22", "3389"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "vm"
      name                       = "AllowDbSubnetMySQLOutbound"
      priority                   = 1000
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3306"
      source_address_prefix      = "*"
      destination_address_prefix = "10.10.3.0/24"
    },
    {
      target_nsg                 = "vm"
      name                       = "AllowInternetOutbound"
      priority                   = 1100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    },
    {
      target_nsg                 = "vm"
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "vm"
      name                       = "DenyAllOutbound"
      priority                   = 4096
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    # AzureBastionSubnet
    {
      target_nsg                 = "bastion"
      name                       = "AllowHttpsInbound"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "bastion"
      name                       = "AllowGatewayManagerInbound"
      priority                   = 1100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "bastion"
      name                       = "AllowAzureLoadBalancerInbound"
      priority                   = 1200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "bastion"
      name                       = "AllowBastionHostCommunication"
      priority                   = 1300
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["8080", "5701"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      target_nsg                 = "bastion"
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      target_nsg                 = "bastion"
      name                       = "AllowSshRdpOutbound"
      priority                   = 1000
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["22", "3389"]
      source_address_prefix      = "*"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      target_nsg                 = "bastion"
      name                       = "AllowAzureCloudOutbound"
      priority                   = 1100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "AzureCloud"
    },
    {
      target_nsg                 = "bastion"
      name                       = "AllowBastionCommunication"
      priority                   = 1200
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["8080", "5701"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      target_nsg                 = "bastion"
      name                       = "AllowHttpOutbound"
      priority                   = 1300
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    },
    {
      target_nsg                 = "bastion"
      name                       = "DenyAllOutbound"
      priority                   = 4096
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
  ]
}

variable "storage" {
  type = map(object({
    name                          = string
    account_tier                  = string
    account_kind                  = string
    account_replication_type      = string
    access_tier                   = string
    https_traffic_only_enabled    = bool
    public_network_access_enabled = bool
    is_hns_enabled                = bool
    blob_properties = object({
      versioning_enabled                = bool
      change_feed_enabled               = bool
      last_access_time_enabled          = bool
      delete_retention_policy           = number
      container_delete_retention_policy = number
    })
    network_rules = object({
      default_action             = string
      bypass                     = list(string)
      ip_rules                   = list(string)
      virtual_network_subnet_ids = list(string)
    })
  }))
  default = {
    app = {
      name                          = "app"
      account_tier                  = "Standard"
      account_kind                  = "StorageV2"
      account_replication_type      = "LRS"
      access_tier                   = "Hot"
      https_traffic_only_enabled    = true
      public_network_access_enabled = true
      is_hns_enabled                = false
      blob_properties = {
        versioning_enabled                = false
        change_feed_enabled               = false
        last_access_time_enabled          = false
        delete_retention_policy           = 7
        container_delete_retention_policy = 7
      }
      network_rules = null
    }
    func = {
      name                          = "func"
      account_tier                  = "Standard"
      account_kind                  = "StorageV2"
      account_replication_type      = "LRS"
      access_tier                   = "Hot"
      https_traffic_only_enabled    = true
      public_network_access_enabled = true
      is_hns_enabled                = false
      blob_properties = {
        versioning_enabled                = false
        change_feed_enabled               = false
        last_access_time_enabled          = false
        delete_retention_policy           = 7
        container_delete_retention_policy = 7
      }
      network_rules = {
        default_action             = "Deny"
        bypass                     = ["AzureServices"]
        ip_rules                   = ["MyIP"]
        virtual_network_subnet_ids = []
      }
    }
    log = {
      name                          = "log"
      account_tier                  = "Standard"
      account_kind                  = "StorageV2"
      account_replication_type      = "LRS"
      access_tier                   = "Hot"
      https_traffic_only_enabled    = true
      public_network_access_enabled = true
      is_hns_enabled                = false
      blob_properties = {
        versioning_enabled                = false
        change_feed_enabled               = false
        last_access_time_enabled          = false
        delete_retention_policy           = 7
        container_delete_retention_policy = 7
      }
      network_rules = {
        default_action             = "Deny"
        bypass                     = ["AzureServices"]
        ip_rules                   = ["MyIP"]
        virtual_network_subnet_ids = []
      }
    }
  }
}

variable "blob_container" {
  type = map(map(string))
  default = {
    app_static = {
      target_storage_account = "app"
      container_name         = "static"
      container_access_type  = "blob"
    }
    app_media = {
      target_storage_account = "app"
      container_name         = "media"
      container_access_type  = "blob"
    }
  }
}

variable "storage_management_policy" {
  type = map(object({
    name                   = string
    target_storage_account = string
    blob_types             = list(string)
    actions = object({
      base_blob = optional(object({
        auto_tier_to_hot_from_cool_enabled                             = optional(bool)
        delete_after_days_since_creation_greater_than                  = optional(number)
        delete_after_days_since_last_access_time_greater_than          = optional(number)
        delete_after_days_since_modification_greater_than              = optional(number)
        tier_to_archive_after_days_since_creation_greater_than         = optional(number)
        tier_to_archive_after_days_since_last_access_time_greater_than = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        tier_to_archive_after_days_since_modification_greater_than     = optional(number)
        tier_to_cold_after_days_since_creation_greater_than            = optional(number)
        tier_to_cold_after_days_since_last_access_time_greater_than    = optional(number)
        tier_to_cold_after_days_since_modification_greater_than        = optional(number)
        tier_to_cool_after_days_since_creation_greater_than            = optional(number)
        tier_to_cool_after_days_since_last_access_time_greater_than    = optional(number)
        tier_to_cool_after_days_since_modification_greater_than        = optional(number)
      }))
      snapshot = optional(object({
        change_tier_to_archive_after_days_since_creation               = optional(number)
        change_tier_to_cool_after_days_since_creation                  = optional(number)
        delete_after_days_since_creation_greater_than                  = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        tier_to_cold_after_days_since_creation_greater_than            = optional(number)
      }))
      version = optional(object({
        change_tier_to_archive_after_days_since_creation               = optional(number)
        change_tier_to_cool_after_days_since_creation                  = optional(number)
        delete_after_days_since_creation                               = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        tier_to_cold_after_days_since_creation_greater_than            = optional(number)
      }))
    })
  }))
  default = {
    log = {
      name                   = "move-cold-after-30-days"
      target_storage_account = "log"
      blob_types             = ["blockBlob"]
      actions = {
        base_blob = {
          tier_to_cold_after_days_since_modification_greater_than = 30
          delete_after_days_since_modification_greater_than       = 365
        }
        snapshot = null
        version  = null
      }
    }
  }
}

variable "key_vault" {
  type = map(object({
    name                       = string
    sku_name                   = string
    enable_rbac_authorization  = bool
    purge_protection_enabled   = bool
    soft_delete_retention_days = number
    network_acls = object({
      default_action             = string
      bypass                     = string
      ip_rules                   = list(string)
      virtual_network_subnet_ids = list(string)
    })
  }))
  default = {
    app = {
      name                       = "app"
      sku_name                   = "standard"
      enable_rbac_authorization  = true
      purge_protection_enabled   = false
      soft_delete_retention_days = 7
      network_acls = {
        default_action             = "Deny"
        bypass                     = "None"
        ip_rules                   = ["MyIP"]
        virtual_network_subnet_ids = []
      }
    }
  }
}

variable "log_analytics" {
  type = map(object({
    sku                        = string
    retention_in_days          = number
    internet_ingestion_enabled = bool
    internet_query_enabled     = bool
  }))
  default = {
    logs = {
      sku                        = "PerGB2018"
      retention_in_days          = 30
      internet_ingestion_enabled = false
      internet_query_enabled     = true
    }
  }
}

variable "application_insights" {
  type = map(object({
    name                       = string
    application_type           = string
    target_workspace           = string
    retention_in_days          = number
    internet_ingestion_enabled = bool
    internet_query_enabled     = bool
  }))
  default = {
    app = {
      name                       = "app"
      target_workspace           = "logs"
      application_type           = "web"
      retention_in_days          = 90
      internet_ingestion_enabled = false
      internet_query_enabled     = true
    }
    func = {
      name                       = "func"
      target_workspace           = "logs"
      application_type           = "web"
      retention_in_days          = 90
      internet_ingestion_enabled = false
      internet_query_enabled     = true
    }
  }
}

variable "user_assigned_identity" {
  type = map(object({
    name = string
  }))
  default = {
    app = {
      name = "app"
    }
    func = {
      name = "func"
    }
  }
}

variable "role_assignment" {
  type = map(object({
    target_identity      = string
    role_definition_name = string
  }))
  default = {
    app_acr_pull = {
      target_identity      = "app"
      role_definition_name = "AcrPull"
    }
    app_key_vault_secrets_user = {
      target_identity      = "app"
      role_definition_name = "Key Vault Secrets User"
    }
    app_storage_blob_data_contributor = {
      target_identity      = "app"
      role_definition_name = "Storage Blob Data Contributor"
    }
    func_acr_pull = {
      target_identity      = "func"
      role_definition_name = "AcrPull"
    }
    func_key_vault_secrets_user = {
      target_identity      = "func"
      role_definition_name = "Key Vault Secrets User"
    }
  }
}

variable "custom_domain" {
  type = map(object({
    dns_zone_name             = string
    subdomain                 = string
    target_frontdoor_endpoint = string
  }))
  default = {
    app = {
      dns_zone_name             = "azphoto.xyz"
      subdomain                 = "www"
      target_frontdoor_endpoint = "app"
    }
  }
}

variable "private_dns_zone" {
  type = map(string)
  default = {
    blob      = "privatelink.blob.core.windows.net"
    key_vault = "privatelink.vaultcore.azure.net"
    # Azure Monitor Private Link Scope (AMPLS) のプライベート DNS ゾーン
    monitor  = "privatelink.monitor.azure.com"
    oms      = "privatelink.oms.opinsights.azure.com"
    ods      = "privatelink.ods.opinsights.azure.com"
    agentsvc = "privatelink.agentsvc.azure-automation.net"
  }
}

variable "private_link_scope" {
  type = map(object({
    name                  = string
    ingestion_access_mode = string
    query_access_mode     = string
  }))
  default = {
    app = {
      name                  = "app"
      ingestion_access_mode = "Open"
      query_access_mode     = "Open"
    }
  }
}

variable "frontdoor_profile" {
  type = object({
    sku_name                 = string
    response_timeout_seconds = number
  })
  default = {
    sku_name                 = "Standard_AzureFrontDoor"
    response_timeout_seconds = 60
  }
}

variable "frontdoor_endpoint" {
  type = map(object({
    name = string
  }))
  default = {
    app = {
      name = "app"
    }
  }
}

variable "frontdoor_origin_group" {
  type = map(object({
    name                                                      = string
    session_affinity_enabled                                  = bool
    restore_traffic_time_to_healed_or_new_endpoint_in_minutes = number
    health_probe = object({
      interval_in_seconds = number
      path                = string
      protocol            = string
      request_type        = string
    })
    load_balancing = object({
      additional_latency_in_milliseconds = number
      sample_size                        = number
      successful_samples_required        = number
    })
  }))
  default = {
    app = {
      name                                                      = "app"
      session_affinity_enabled                                  = false
      restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 0
      health_probe = {
        interval_in_seconds = 100
        path                = "/"
        protocol            = "Https"
        request_type        = "HEAD"
      }
      load_balancing = {
        additional_latency_in_milliseconds = 50
        sample_size                        = 4
        successful_samples_required        = 3
      }
    }
    blob = {
      name                                                      = "blob"
      session_affinity_enabled                                  = false
      restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 0
      health_probe = {
        interval_in_seconds = 100
        path                = "/"
        protocol            = "Https"
        request_type        = "HEAD"
      }
      load_balancing = {
        additional_latency_in_milliseconds = 50
        sample_size                        = 4
        successful_samples_required        = 3
      }
    }
  }
}

variable "frontdoor_origin" {
  type = map(object({
    name                           = string
    target_frontdoor_origin_group  = string
    target_backend_origin          = string
    certificate_name_check_enabled = bool
    http_port                      = number
    https_port                     = number
    priority                       = number
    weight                         = number
  }))
  default = {
    # app = {
    #   name                           = "app"
    #   target_frontdoor_origin_group  = "app"
    #   target_backend_origin          = "app"
    #   certificate_name_check_enabled = true
    #   http_port                      = 80
    #   https_port                     = 443
    #   priority                       = 1
    #   weight                         = 1000
    # }
    blob = {
      name                           = "blob"
      target_frontdoor_origin_group  = "blob"
      target_backend_origin          = "blob"
      certificate_name_check_enabled = true
      http_port                      = 80
      https_port                     = 443
      priority                       = 1
      weight                         = 1000
    }
  }
}

variable "frontdoor_route" {
  type = map(object({
    name                          = string
    target_frontdoor_endpoint     = string
    target_frontdoor_origin_group = string
    target_frontdoor_origin       = string
    target_custom_domain          = string
    forwarding_protocol           = string
    https_redirect_enabled        = bool
    patterns_to_match             = list(string)
    supported_protocols           = list(string)
    link_to_default_domain        = bool
    cache = object({
      compression_enabled           = bool
      query_string_caching_behavior = string
      query_strings                 = list(string)
      content_types_to_compress     = list(string)
    })
  }))
  default = {
    # app = {
    #   name                          = "app"
    #   target_frontdoor_endpoint     = "app"
    #   target_frontdoor_origin_group = "app"
    #   target_frontdoor_origin       = "app"
    #   target_custom_domain          = "app"
    #   forwarding_protocol           = "HttpsOnly"
    #   https_redirect_enabled        = true
    #   patterns_to_match             = ["/*"]
    #   supported_protocols           = ["Http", "Https"]
    #   link_to_default_domain        = true
    #   cache                         = null
    # }
    blob = {
      name                          = "blob"
      target_frontdoor_endpoint     = "app"
      target_frontdoor_origin_group = "blob"
      target_frontdoor_origin       = "blob"
      target_custom_domain          = "app"
      forwarding_protocol           = "HttpsOnly"
      https_redirect_enabled        = true
      patterns_to_match             = ["/media/*", "/static/*"]
      supported_protocols           = ["Http", "Https"]
      link_to_default_domain        = true
      cache = {
        compression_enabled           = true
        query_string_caching_behavior = "IgnoreQueryString"
        query_strings                 = []
        content_types_to_compress     = ["text/html", "text/css", "text/javascript"]
      }
    }
  }
}

variable "frontdoor_security_policy" {
  type = map(object({
    name                   = string
    target_firewall_policy = string
    patterns_to_match      = list(string)
  }))
  default = {
    app = {
      name                   = "app"
      target_firewall_policy = "app"
      patterns_to_match      = ["/*"]
    }
  }
}

variable "frontdoor_firewall_policy" {
  type = map(object({
    name                              = string
    sku_name                          = string
    mode                              = string
    custom_block_response_status_code = number
  }))
  default = {
    app = {
      name                              = "IPRestrictionPolicy"
      sku_name                          = "Standard_AzureFrontDoor"
      mode                              = "Prevention"
      custom_block_response_status_code = 403
    }
  }
}

variable "frontdoor_firewall_custom_rule" {
  type = map(object({
    target_firewall_policy = string
    priority               = number
    type                   = string
    action                 = string
    match_condition = object({
      match_variable     = string
      operator           = string
      negation_condition = bool
      match_values       = list(string)
    })
  }))
  default = {
    AllowClientIP = {
      target_firewall_policy = "app"
      priority               = 100
      type                   = "MatchRule"
      action                 = "Block"
      match_condition = {
        match_variable     = "RemoteAddr"
        operator           = "IPMatch"
        negation_condition = true # 含まない場合
        match_values       = ["MyIP"]
      }
    }
  }
}

variable "container_registry" {
  type = map(object({
    sku_name                      = string
    admin_enabled                 = bool
    public_network_access_enabled = bool
    zone_redundancy_enabled       = bool
  }))
  default = {
    app = {
      sku_name                      = "Basic"
      admin_enabled                 = false
      public_network_access_enabled = true
      zone_redundancy_enabled       = false
    }
  }
}

variable "app_service_plan" {
  type = map(object({
    name     = string
    os_type  = string
    sku_name = string
  }))
  default = {
    app = {
      name     = "app"
      os_type  = "Linux"
      sku_name = "B1"
    }
    # func = {
    #   name     = "func"
    #   os_type  = "Linux"
    #   sku_name = "B1"
    # }
  }
}

variable "app_service" {
  type = map(object({
    name                                           = string
    target_service_plan                            = string
    target_subnet                                  = string
    target_user_assigned_identity                  = string
    ftp_publish_basic_authentication_enabled       = bool
    webdeploy_publish_basic_authentication_enabled = bool
    https_only                                     = bool
    public_network_access_enabled                  = bool
    site_config = object({
      always_on                               = bool
      ftps_state                              = string
      vnet_route_all_enabled                  = bool
      scm_use_main_ip_restriction             = bool
      container_registry_use_managed_identity = bool
      cors = object({
        support_credentials = bool
      })
    })
    ip_restriction = map(object({
      name        = string
      priority    = number
      action      = string
      ip_address  = string
      service_tag = string
    }))
    scm_ip_restriction = map(object({
      name        = string
      priority    = number
      action      = string
      ip_address  = string
      service_tag = string
    }))
  }))
  default = {
    app = {
      name                                           = "app"
      target_service_plan                            = "app"
      target_subnet                                  = "app"
      target_user_assigned_identity                  = "app"
      ftp_publish_basic_authentication_enabled       = false
      webdeploy_publish_basic_authentication_enabled = false
      https_only                                     = true
      public_network_access_enabled                  = true
      site_config = {
        always_on                               = true
        ftps_state                              = "Disabled"
        vnet_route_all_enabled                  = true
        scm_use_main_ip_restriction             = false
        container_registry_use_managed_identity = true
        cors = {
          support_credentials = true
        }
      }
      ip_restriction = {
        frontdoor = {
          name        = "AllowFrontDoor"
          priority    = 100
          action      = "Allow"
          ip_address  = null
          service_tag = "AzureFrontDoor.Backend"
        }
        myip = {
          name        = "AllowMyIP"
          priority    = 200
          action      = "Allow"
          ip_address  = "MyIP"
          service_tag = null
        }
      }
      scm_ip_restriction = {
        devops = {
          name        = "AllowDevOps"
          priority    = 100
          action      = "Allow"
          ip_address  = null
          service_tag = "AzureCloud"
        }
        myip = {
          name        = "AllowMyIP"
          priority    = 200
          action      = "Allow"
          ip_address  = "MyIP"
          service_tag = null
        }
      }
    }
  }
}

variable "function" {
  type = map(object({
    name                                           = string
    target_service_plan                            = string
    target_subnet                                  = string
    target_key_vault_secret                        = string
    target_user_assigned_identity                  = string
    target_application_insights                    = string
    functions_extension_version                    = string
    ftp_publish_basic_authentication_enabled       = bool
    webdeploy_publish_basic_authentication_enabled = bool
    https_only                                     = bool
    public_network_access_enabled                  = bool
    builtin_logging_enabled                        = bool
    site_config = object({
      always_on                               = bool
      ftps_state                              = string
      vnet_route_all_enabled                  = bool
      scm_use_main_ip_restriction             = bool
      container_registry_use_managed_identity = bool
    })
    ip_restriction = map(object({
      name        = string
      priority    = number
      action      = string
      ip_address  = string
      service_tag = string
    }))
    scm_ip_restriction = map(object({
      name        = string
      priority    = number
      action      = string
      ip_address  = string
      service_tag = string
    }))
    app_service_logs = object({
      disk_quota_mb         = number
      retention_period_days = number
    })
  }))
  default = {
    func = {
      name                                           = "func"
      target_service_plan                            = "func"
      target_subnet                                  = "func"
      target_key_vault_secret                        = "FUNCTION_STORAGE_ACCOUNT_CONNECTION_STRING"
      target_user_assigned_identity                  = "func"
      target_application_insights                    = "func"
      functions_extension_version                    = "~4"
      ftp_publish_basic_authentication_enabled       = false
      webdeploy_publish_basic_authentication_enabled = false
      https_only                                     = true
      public_network_access_enabled                  = true
      builtin_logging_enabled                        = false
      site_config = {
        always_on                               = true
        ftps_state                              = "Disabled"
        vnet_route_all_enabled                  = true
        scm_use_main_ip_restriction             = false
        container_registry_use_managed_identity = true
      }
      ip_restriction = {
        myip = {
          name        = "AllowMyIP"
          priority    = 100
          action      = "Allow"
          ip_address  = "MyIP"
          service_tag = null
        }
      }
      scm_ip_restriction = {
        devops = {
          name        = "AllowDevOps"
          priority    = 100
          action      = "Allow"
          ip_address  = null
          service_tag = "AzureCloud"
        }
        myip = {
          name        = "AllowMyIP"
          priority    = 200
          action      = "Allow"
          ip_address  = "MyIP"
          service_tag = null
        }
      }
      app_service_logs = {
        disk_quota_mb         = 35
        retention_period_days = 7
      }
    }
  }
}

variable "openai" {
  type = map(object({
    name     = string
    location = string
    kind     = string
    sku_name = string
    network_acls = object({
      default_action = string
      ip_rules       = list(string)
    })
  }))
  default = {
    app = {
      name     = "app"
      location = "eastus2"
      kind     = "OpenAI"
      sku_name = "S0"
      network_acls = {
        default_action = "Deny"
        ip_rules       = ["MyIP"]
      }
    }
  }
}

variable "openai_deployment" {
  type = map(object({
    name                   = string
    target_openai          = string
    version_upgrade_option = string
    model = object({
      name    = string
      version = optional(string)
    })
    sku = object({
      name     = string
      capacity = number
    })
  }))
  default = {
    o1-mini = {
      name                   = "o1-mini"
      target_openai          = "app"
      version_upgrade_option = "OnceNewDefaultVersionAvailable"
      model = {
        name    = "o1-mini"
        version = "2024-09-12"
      }
      sku = {
        name     = "GlobalStandard"
        capacity = 10
      }
    }
    o3-mini = {
      name                   = "o3-mini"
      target_openai          = "app"
      version_upgrade_option = "OnceNewDefaultVersionAvailable"
      model = {
        name    = "o3-mini"
        version = "2025-01-31"
      }
      sku = {
        name     = "GlobalStandard"
        capacity = 10
      }
    }
  }
}

variable "aisearch" {
  type = map(object({
    name                          = string
    sku                           = string
    semantic_search_sku           = string
    partition_count               = number
    replica_count                 = number
    public_network_access_enabled = bool
    network_rule_bypass_option    = string
    allowed_ips                   = list(string)
  }))
  default = {
    app = {
      name                          = "app"
      sku                           = "basic"
      semantic_search_sku           = "free"
      partition_count               = 1
      replica_count                 = 1
      public_network_access_enabled = true
      network_rule_bypass_option    = "AzureServices"
      allowed_ips                   = ["MyIP"]
    }
  }
}

variable "cosmosdb_account" {
  type = map(object({
    name                          = string
    offer_type                    = string
    kind                          = string
    free_tier_enabled             = bool
    public_network_access_enabled = bool
    ip_range_filter               = list(string)
    consistency_policy = object({
      consistency_level       = string
      max_interval_in_seconds = number
      max_staleness_prefix    = number
    })
    geo_location = object({
      location          = string
      failover_priority = number
      zone_redundant    = bool
    })
    capacity = object({
      total_throughput_limit = number
    })
    backup = object({
      type = string
      tier = string
    })
  }))
  default = {
    app = {
      name                          = "app"
      offer_type                    = "Standard"
      kind                          = "GlobalDocumentDB"
      free_tier_enabled             = false
      public_network_access_enabled = true
      ip_range_filter               = ["MyIP"]
      consistency_policy = {
        consistency_level       = "Session"
        max_interval_in_seconds = 5
        max_staleness_prefix    = 100
      }
      geo_location = {
        location          = "japaneast"
        failover_priority = 0
        zone_redundant    = false
      }
      capacity = {
        total_throughput_limit = 1000
      }
      backup = {
        type = "Continuous"
        tier = "Continuous7Days"
      }
    }
  }
}

variable "cosmosdb_sql_database" {
  type = map(object({
    name                    = string
    target_cosmosdb_account = string
    autoscale_settings = object({
      max_throughput = number
    })
  }))
  default = {
    database1 = {
      name                    = "database1"
      target_cosmosdb_account = "app"
      autoscale_settings = {
        max_throughput = 1000
      }
    }
  }
}

variable "cosmosdb_sql_container" {
  type = map(object({
    name                         = string
    target_cosmosdb_account      = string
    target_cosmosdb_sql_database = string
    partition_key_paths          = list(string)
    partition_key_version        = number
    autoscale_settings = object({
      max_throughput = number
    })
  }))
  default = {
    container1 = {
      name                         = "container1"
      target_cosmosdb_account      = "app"
      target_cosmosdb_sql_database = "database1"
      partition_key_paths          = ["/id"]
      partition_key_version        = 2
      autoscale_settings           = null
    }
  }
}

variable "mysql_flexible_server" {
  type = map(object({
    name                         = string
    target_vnet                  = string
    target_subnet                = string
    sku_name                     = string
    version                      = string
    backup_retention_days        = number
    geo_redundant_backup_enabled = bool
    zone                         = string
    high_availability = object({
      mode                      = string
      standby_availability_zone = string
    })
    storage = object({
      auto_grow_enabled = bool
      iops              = number
      size_gb           = number
    })
  }))
  default = {
    app = {
      name                         = "app"
      target_vnet                  = "spoke1"
      target_subnet                = "db"
      sku_name                     = "B_Standard_B1ms"
      version                      = "8.0.21"
      backup_retention_days        = 7
      geo_redundant_backup_enabled = false
      zone                         = "2"
      high_availability            = null
      storage = {
        auto_grow_enabled = true
        iops              = 360
        size_gb           = 20
      }
    }
  }
}

variable "mysql_authentication" {
  type = map(object({
    administrator_login               = string
    administrator_password_wo         = string
    administrator_password_wo_version = number
  }))
  default = {
    app = {
      administrator_login               = "your-username"
      administrator_password_wo         = "your-password"
      administrator_password_wo_version = 1
    }
  }
}

variable "mysql_flexible_database" {
  type = map(map(string))
  default = {
    database1 = {
      name                = "database1"
      target_mysql_server = "app"
      charset             = "utf8mb4"
      collation           = "utf8mb4_0900_ai_ci"
    }
  }
}

variable "redis_cache" {
  type = map(object({
    name                          = string
    capacity                      = number
    family                        = string
    sku_name                      = string
    redis_version                 = number
    public_network_access_enabled = bool
    non_ssl_port_enabled          = bool
    minimum_tls_version           = string
  }))
  default = {
    app = {
      name                          = "app"
      capacity                      = 0
      family                        = "C"
      sku_name                      = "Basic"
      redis_version                 = 6
      public_network_access_enabled = false
      non_ssl_port_enabled          = false
      minimum_tls_version           = "1.2"
    }
  }
}

variable "vm" {
  type = map(object({
    name                            = string
    target_subnet                   = string
    vm_size                         = string
    zone                            = string
    allow_extension_operations      = bool
    disable_password_authentication = bool
    encryption_at_host_enabled      = bool
    patch_mode                      = string
    secure_boot_enabled             = bool
    vtpm_enabled                    = bool
    os_disk = object({
      os_disk_cache             = string
      os_disk_type              = string
      os_disk_size              = number
      write_accelerator_enabled = bool
    })
    source_image_reference = object({
      offer     = string
      publisher = string
      sku       = string
      version   = string
    })
    public_ip = object({
      sku               = string
      allocation_method = string
      zones             = list(string)
    })
    vm_shutdown_schedule = object({
      daily_recurrence_time = string
      timezone              = string
      enabled               = bool
      notification_settings = object({
        enabled         = bool
        time_in_minutes = number
        email           = string
      })
    })
  }))
  default = {
    jumpbox = {
      name                            = "jumpbox"
      target_subnet                   = "vm"
      vm_size                         = "Standard_DS1_v2"
      zone                            = "1"
      allow_extension_operations      = true
      disable_password_authentication = true
      encryption_at_host_enabled      = false
      patch_mode                      = "ImageDefault"
      secure_boot_enabled             = true
      vtpm_enabled                    = true
      os_disk = {
        os_disk_cache             = "ReadWrite"
        os_disk_type              = "Standard_LRS"
        os_disk_size              = 30
        write_accelerator_enabled = false
      }
      source_image_reference = {
        offer     = "ubuntu-24_04-lts"
        publisher = "canonical"
        sku       = "server"
        version   = "latest"
      }
      public_ip = null
      vm_shutdown_schedule = {
        daily_recurrence_time = "1900"
        timezone              = "Tokyo Standard Time"
        enabled               = true
        notification_settings = {
          enabled         = false
          time_in_minutes = 15
          email           = "admin@example.com"
        }
      }
    }
  }
}

variable "vm_admin_username" {
  type    = string
  default = "azureuser"
}

variable "vmss" {
  type = map(object({
    name                        = string
    target_subnet               = string
    sku_name                    = string
    platform_fault_domain_count = number
    encryption_at_host_enabled  = bool
    instances                   = number
    zone_balance                = bool
    zones                       = list(string)
    os_profile = object({
      linux_configuration = object({
        patch_assessment_mode = string
        patch_mode            = string
        provision_vm_agent    = bool
      })
    })
    public_ip_address_enabled = bool
    os_disk = object({
      os_disk_cache             = string
      os_disk_type              = string
      os_disk_size              = number
      write_accelerator_enabled = bool
    })
    source_image_reference = object({
      offer     = string
      publisher = string
      sku       = string
      version   = string
    })
  }))
  default = {
    app = {
      name                        = "app"
      target_subnet               = "vm"
      sku_name                    = "Standard_DS1_v2"
      platform_fault_domain_count = 1
      encryption_at_host_enabled  = false
      instances                   = 2
      zone_balance                = true
      zones                       = ["1", "2", "3"]
      os_profile = {
        linux_configuration = {
          patch_assessment_mode = "ImageDefault"
          patch_mode            = "ImageDefault"
          provision_vm_agent    = true
        }
      }
      public_ip_address_enabled = true
      os_disk = {
        os_disk_cache             = "ReadWrite"
        os_disk_type              = "Standard_LRS"
        os_disk_size              = 30
        write_accelerator_enabled = false
      }
      source_image_reference = {
        offer     = "ubuntu-24_04-lts"
        publisher = "canonical"
        sku       = "server"
        version   = "latest"
      }
    }
  }
}

variable "vmss_admin_username" {
  type    = string
  default = "azureuser"
}

variable "loadbalancer" {
  type = object({
    sku               = string
    frontend_ip_name  = string
    backend_pool_name = string
    public_ip = object({
      sku               = string
      allocation_method = string
      zones             = list(string)
    })
    probe = object({
      name                = string
      port                = number
      interval_in_seconds = number
      number_of_probes    = number
      protocol            = string
      request_path        = string
    })
    rule = object({
      name                           = string
      protocol                       = string
      frontend_port                  = number
      backend_port                   = number
      frontend_ip_configuration_name = string
      enable_floating_ip             = bool
      idle_timeout_in_minutes        = number
      load_distribution              = string
      disable_outbound_snat          = bool
      enable_tcp_reset               = bool
    })
  })
  default = {
    sku               = "Standard"
    frontend_ip_name  = "frontend"
    backend_pool_name = "bepool"
    public_ip = {
      sku               = "Standard"
      allocation_method = "Static"
      zones             = ["1", "2", "3"]
    }
    probe = {
      name                = "http-probe"
      port                = 80
      interval_in_seconds = 5
      number_of_probes    = 3
      protocol            = "Http"
      request_path        = "/"
    }
    rule = {
      name                           = "http-rule"
      protocol                       = "Tcp"
      frontend_port                  = 80
      backend_port                   = 80
      frontend_ip_configuration_name = "frontend"
      enable_floating_ip             = false
      idle_timeout_in_minutes        = 4
      load_distribution              = "Default"
      disable_outbound_snat          = false
      enable_tcp_reset               = false
    }
  }
}

variable "bastion" {
  type = object({
    target_subnet             = string
    sku                       = string
    scale_units               = number
    zones                     = list(string)
    copy_paste_enabled        = bool
    file_copy_enabled         = bool
    ip_connect_enabled        = bool
    kerberos_enabled          = bool
    shareable_link_enabled    = bool
    tunneling_enabled         = bool
    session_recording_enabled = bool
    public_ip = object({
      sku               = string
      allocation_method = string
      zones             = list(string)
    })
  })
  default = {
    target_subnet             = "bastion"
    sku                       = "Standard"
    scale_units               = 2
    zones                     = [] # Japan East is not supported at 2025/03
    copy_paste_enabled        = true
    file_copy_enabled         = true
    ip_connect_enabled        = true
    kerberos_enabled          = false
    shareable_link_enabled    = true
    tunneling_enabled         = true
    session_recording_enabled = false
    public_ip = {
      sku               = "Standard"
      allocation_method = "Static"
      zones             = ["1", "2", "3"]
    }
  }
}

variable "nat_gateway" {
  type = object({
    target_subnets          = list(string)
    sku_name                = string
    idle_timeout_in_minutes = number
    zones                   = list(string)
    public_ip = object({
      sku               = string
      allocation_method = string
      zones             = list(string)
    })
  })
  default = {
    target_subnets          = ["vm", "app", "func"]
    sku_name                = "Standard"
    idle_timeout_in_minutes = 4
    zones                   = ["1"]
    public_ip = {
      sku               = "Standard"
      allocation_method = "Static"
      zones             = ["1"]
    }
  }
}

variable "action_group" {
  type = map(object({
    name = string
    email_receivers = list(object({
      name                    = string
      email_address           = string
      use_common_alert_schema = bool
    }))
  }))
  default = {
    info = {
      name = "info"
      email_receivers = [
        {
          name                    = "運用チーム"
          email_address           = "support@example.com"
          use_common_alert_schema = true
        }
      ]
    }
  }
}

variable "service_health_alert" {
  type = map(object({
    name                = string
    target_action_group = string
    events              = list(string)
  }))
  default = {
    info = {
      name                = "Service Health Alert (Except Incidents)"
      target_action_group = "info"
      events              = ["Maintenance", "Informational", "ActionRequired", "Security"]
    }
    # incident = {
    #   name                = "Service Health Alert (Incidents Only)"
    #   target_action_group = "incident"
    #   events              = ["Incident"]
    # }
  }
}
