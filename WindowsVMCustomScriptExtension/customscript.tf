resource "azurerm_storage_account" "vmstore135344" {
  name                     = "vmstore135344"
  location                 = local.resource_group_location
  resource_group_name      = local.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

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

resource "azurerm_virtual_machine_extension" "vmextension" {
  count                = var.number_of_machines
  name                 = "vmextension"
  virtual_machine_id   = azurerm_windows_virtual_machine.appvm[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "fileUris": ["https://${azurerm_storage_account.vmstore135344.name}.blob.core.windows.net/data/IIS_Config.ps1"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file IIS_Config.ps1"     
    }
SETTINGS

  depends_on = [ 
    azurerm_storage_container.data
 ]
}