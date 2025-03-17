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
