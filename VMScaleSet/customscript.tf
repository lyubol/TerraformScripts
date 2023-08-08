# The storage account will be used to store the script for Custom Script extension

resource "azurerm_storage_account" "vmstore45776873" {
  name                     = "vmstore45776873"
  resource_group_name      = local.resource_group_name
  location                 = local.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind = "StorageV2"  
  depends_on = [
    azurerm_resource_group.appgrp
  ]
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = "vmstore45776873"
  container_access_type = "blob"
  depends_on=[
    azurerm_storage_account.vmstore45776873
    ]
}

resource "azurerm_storage_blob" "IISConfig" {
  name                   = "IIS_Config.ps1"
  storage_account_name   = "vmstore45776873"
  storage_container_name = "data"
  type                   = "Block"
  source                 = "IIS_Config.ps1"
  depends_on = [
    azurerm_storage_container.data
  ]
}

resource "azurerm_virtual_machine_scale_set_extension" "scalesetextension" {
  name                         = "scalesetextension"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.appset.id
  publisher                    = "Microsoft.Compute"
  type                         = "CustomScriptExtension"
  type_handler_version         = "1.9"
  depends_on = [
    azurerm_storage_blob.IISConfig
  ]
  settings = <<SETTINGS
    {
        "fileUris": ["https://${azurerm_storage_account.vmstore45776873.name}.blob.core.windows.net/data/IIS_Config.ps1"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file IIS_Config.ps1"     
    }
SETTINGS
}
