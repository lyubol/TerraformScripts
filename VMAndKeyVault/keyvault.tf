data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "appvault" {
  name                        = "appvault156657"
  location                    = local.resource_group_location
  resource_group_name         = local.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Purge", "Recover", "Set"
    ]
  }

  depends_on = [ 
    azurerm_resource_group.appgrp
 ]
}

resource "azurerm_key_vault_secret" "vmpassword" {
  name         = "vmpassword"
  value        = "Azure@123"
  key_vault_id = azurerm_key_vault.appvault.id

  depends_on = [ 
    azurerm_key_vault.appvault
 ]
}