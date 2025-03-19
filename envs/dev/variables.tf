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
