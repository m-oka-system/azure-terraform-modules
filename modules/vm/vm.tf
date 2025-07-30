#################################
# Virtual machines
################################
resource "azurerm_public_ip" "this" {
  for_each            = { for k, v in var.vm : k => v if v.public_ip != null }
  name                = "ip-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name = var.resource_group_name
  location            = var.common.location
  sku                 = each.value.public_ip.sku
  allocation_method   = each.value.public_ip.allocation_method
  zones               = each.value.public_ip.zones

  tags = var.tags
}

resource "azurerm_network_interface" "this" {
  for_each            = var.vm
  name                = "nic-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name = var.resource_group_name
  location            = var.common.location

  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet[each.value.target_subnet].id
    public_ip_address_id          = each.value.public_ip != null ? azurerm_public_ip.this[each.key].id : null
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "this" {
  for_each                        = { for k, v in var.vm : k => v if v.os_type == "Linux" }
  name                            = "vm-${each.value.name}-${var.common.project}-${var.common.env}"
  computer_name                   = "vm-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name             = var.resource_group_name
  location                        = var.common.location
  size                            = each.value.vm_size
  admin_username                  = var.vm_admin_username
  zone                            = each.value.zone
  allow_extension_operations      = each.value.allow_extension_operations
  disable_password_authentication = each.value.disable_password_authentication
  encryption_at_host_enabled      = each.value.encryption_at_host_enabled
  patch_mode                      = each.value.patch_mode
  secure_boot_enabled             = each.value.secure_boot_enabled
  vtpm_enabled                    = each.value.vtpm_enabled
  custom_data                     = filebase64("${path.module}/userdata.sh")

  network_interface_ids = [
    azurerm_network_interface.this[each.key].id,
  ]

  priority        = "Spot"
  max_bid_price   = -1
  eviction_policy = "Deallocate"

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.public_key
  }

  boot_diagnostics {}

  os_disk {
    name                      = "osdisk-${each.value.name}-${var.common.project}-${var.common.env}"
    caching                   = each.value.os_disk.os_disk_cache
    storage_account_type      = each.value.os_disk.os_disk_type
    disk_size_gb              = each.value.os_disk.os_disk_size
    write_accelerator_enabled = each.value.os_disk.write_accelerator_enabled
  }

  source_image_reference {
    offer     = each.value.source_image_reference.offer
    publisher = each.value.source_image_reference.publisher
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }

  tags = var.tags
}

resource "azurerm_windows_virtual_machine" "this" {
  for_each                   = { for k, v in var.vm : k => v if v.os_type == "Windows" }
  name                       = "vm-${each.value.name}-${var.common.project}-${var.common.env}"
  computer_name              = substr("${each.value.name}-${substr(var.common.project, 0, 3)}-${substr(var.common.env, 0, 3)}", 0, 15)
  resource_group_name        = var.resource_group_name
  location                   = var.common.location
  size                       = each.value.vm_size
  admin_username             = var.vm_admin_username
  admin_password             = var.vm_admin_password
  zone                       = each.value.zone
  allow_extension_operations = each.value.allow_extension_operations
  encryption_at_host_enabled = each.value.encryption_at_host_enabled
  patch_mode                 = each.value.patch_mode
  secure_boot_enabled        = each.value.secure_boot_enabled
  vtpm_enabled               = each.value.vtpm_enabled

  network_interface_ids = [
    azurerm_network_interface.this[each.key].id,
  ]

  priority        = "Spot"
  max_bid_price   = -1
  eviction_policy = "Deallocate"

  boot_diagnostics {}

  os_disk {
    name                      = "osdisk-${each.value.name}-${var.common.project}-${var.common.env}"
    caching                   = each.value.os_disk.os_disk_cache
    storage_account_type      = each.value.os_disk.os_disk_type
    disk_size_gb              = each.value.os_disk.os_disk_size
    write_accelerator_enabled = each.value.os_disk.write_accelerator_enabled
  }

  source_image_reference {
    offer     = each.value.source_image_reference.offer
    publisher = each.value.source_image_reference.publisher
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }

  tags = var.tags
}

locals {
  vm_ids = merge(
    { for k, v in azurerm_linux_virtual_machine.this : k => v.id },
    { for k, v in azurerm_windows_virtual_machine.this : k => v.id }
  )
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "this" {
  for_each              = var.vm
  location              = var.common.location
  virtual_machine_id    = local.vm_ids[each.key]
  daily_recurrence_time = each.value.vm_shutdown_schedule.daily_recurrence_time
  timezone              = each.value.vm_shutdown_schedule.timezone
  enabled               = each.value.vm_shutdown_schedule.enabled

  notification_settings {
    enabled         = each.value.vm_shutdown_schedule.notification_settings.enabled
    time_in_minutes = each.value.vm_shutdown_schedule.notification_settings.time_in_minutes
    email           = each.value.vm_shutdown_schedule.notification_settings.email
  }
}
