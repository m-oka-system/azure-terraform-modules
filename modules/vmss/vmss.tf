#############################################################
# Virtual machine Scale Sets in Flexible Orchestration Mode
#############################################################
resource "azurerm_orchestrated_virtual_machine_scale_set" "this" {
  for_each                    = var.vmss
  name                        = "vmss-${each.value.name}-${var.common.project}-${var.common.env}"
  resource_group_name         = var.resource_group_name
  location                    = var.common.location
  sku_name                    = each.value.sku_name
  platform_fault_domain_count = each.value.platform_fault_domain_count
  encryption_at_host_enabled  = each.value.encryption_at_host_enabled
  instances                   = each.value.instances
  zone_balance                = each.value.zone_balance
  zones                       = each.value.zones

  priority        = "Spot"
  max_bid_price   = -1
  eviction_policy = "Deallocate"

  os_profile {
    custom_data = filebase64("${path.module}/userdata.sh")

    linux_configuration {
      admin_username = var.vmss_admin_username
      admin_ssh_key {
        username   = var.vmss_admin_username
        public_key = var.public_key
      }

      patch_assessment_mode = each.value.os_profile.linux_configuration.patch_assessment_mode
      patch_mode            = each.value.os_profile.linux_configuration.patch_mode
      provision_vm_agent    = each.value.os_profile.linux_configuration.provision_vm_agent
    }
  }

  network_interface {
    name    = "nic-vmss-${each.value.name}-${var.common.project}-${var.common.env}"
    primary = true

    ip_configuration {
      name                                         = "ipconfig1"
      primary                                      = true
      subnet_id                                    = var.subnet[each.value.target_subnet].id
      version                                      = "IPv4"
      application_gateway_backend_address_pool_ids = var.application_gateway_backend_address_pool_ids
      load_balancer_backend_address_pool_ids       = var.load_balancer_backend_address_pool_ids

      dynamic "public_ip_address" {
        for_each = each.value.public_ip_address_enabled ? [true] : []
        content {
          name = "ip-vmss-${each.value.name}-${var.common.project}-${var.common.env}"
        }
      }
    }
  }

  boot_diagnostics {}

  os_disk {
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
