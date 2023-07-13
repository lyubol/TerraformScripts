resource "azurerm_storage_account" "vmstore135344" {
  name                     = "vmstore135344"
  location                 = local.resource_group_location
  resource_group_name      = local.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  network_rules {
    default_action             = "Deny"
    ip_rules                   = ["64.44.156.164"]
    virtual_network_subnet_ids = [azurerm_subnet.subnetA.id]
  }

  depends_on = [ 
    azurerm_resource_group.appgrp
 ]
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.vmstore135344.name
  container_access_type = "blob"

  depends_on = [ 
    azurerm_storage_account.vmstore135344
 ]
}

resource "azurerm_storage_blob" "IISConfig" {
  name                   = "IIS_Config.ps1"
  storage_account_name   = azurerm_storage_account.vmstore135344.name
  storage_container_name = azurerm_storage_container.data.name
  type                   = "Block"
  source                 = "IIS_Config.ps1"
  
  depends_on = [
    azurerm_storage_container.data
  ]
}