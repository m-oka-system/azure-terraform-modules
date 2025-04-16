################################
# Key Vault Certificate
################################
resource "azurerm_key_vault_certificate" "this" {
  for_each     = var.custom_domain
  name         = replace("${each.value.subdomain}.${each.value.dns_zone_name}", ".", "-")
  key_vault_id = var.key_vault[var.key_vault_certificate.target_key_vault].id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      extended_key_usage = [
        "1.3.6.1.5.5.7.3.1",
        "1.3.6.1.5.5.7.3.2",
      ]
      key_usage = [
        "digitalSignature",
        "keyEncipherment",
      ]
      subject            = "CN=${each.value.subdomain}.${each.value.dns_zone_name}"
      validity_in_months = 12

      subject_alternative_names {
        dns_names = [
          each.value.dns_zone_name,
        ]
      }
    }
  }
}
