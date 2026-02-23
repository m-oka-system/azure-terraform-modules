# role_assignment を user_assigned_identity モジュールから role_assignment モジュールに移動
moved {
  from = module.user_assigned_identity.azurerm_role_assignment.this["app_acr_pull"]
  to   = module.role_assignment.azurerm_role_assignment.this["app_acr_pull"]
}

moved {
  from = module.user_assigned_identity.azurerm_role_assignment.this["app_key_vault_secrets_user"]
  to   = module.role_assignment.azurerm_role_assignment.this["app_key_vault_secrets_user"]
}

moved {
  from = module.user_assigned_identity.azurerm_role_assignment.this["app_storage_blob_data_contributor"]
  to   = module.role_assignment.azurerm_role_assignment.this["app_storage_blob_data_contributor"]
}

moved {
  from = module.user_assigned_identity.azurerm_role_assignment.this["func_acr_pull"]
  to   = module.role_assignment.azurerm_role_assignment.this["func_acr_pull"]
}

moved {
  from = module.user_assigned_identity.azurerm_role_assignment.this["func_key_vault_secrets_user"]
  to   = module.role_assignment.azurerm_role_assignment.this["func_key_vault_secrets_user"]
}

moved {
  from = module.user_assigned_identity.azurerm_role_assignment.this["appgw_key_vault_secrets_user"]
  to   = module.role_assignment.azurerm_role_assignment.this["appgw_key_vault_secrets_user"]
}

moved {
  from = module.user_assigned_identity.azurerm_role_assignment.this["mssql_blob_data_contributor"]
  to   = module.role_assignment.azurerm_role_assignment.this["mssql_blob_data_contributor"]
}

moved {
  from = module.user_assigned_identity.azurerm_role_assignment.this["gha_contributor"]
  to   = module.role_assignment.azurerm_role_assignment.this["gha_contributor"]
}

moved {
  from = module.user_assigned_identity.azurerm_role_assignment.this["gha_key_vault_secrets_user"]
  to   = module.role_assignment.azurerm_role_assignment.this["gha_key_vault_secrets_user"]
}

moved {
  from = module.user_assigned_identity.azurerm_role_assignment.this["gha_storage_blob_data_contributor"]
  to   = module.role_assignment.azurerm_role_assignment.this["gha_storage_blob_data_contributor"]
}

moved {
  from = module.user_assigned_identity.azurerm_role_assignment.this["k8s_key_vault_secrets_user"]
  to   = module.role_assignment.azurerm_role_assignment.this["k8s_key_vault_secrets_user"]
}

moved {
  from = module.user_assigned_identity.azurerm_role_assignment.this["certmanager_dns_zone_contributor"]
  to   = module.role_assignment.azurerm_role_assignment.this["certmanager_dns_zone_contributor"]
}
