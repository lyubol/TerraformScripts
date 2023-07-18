resource "azurerm_storage_account" "webstore1353442" {
  name                     = "webstore1353442"
  location                 = local.resource_group_location
  resource_group_name      = local.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  depends_on = [ 
    azurerm_resource_group.appgrp
 ]
}

resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_name  = azurerm_storage_account.webstore1353442.name
  container_access_type = "blob"

  depends_on = [ 
    azurerm_storage_account.webstore1353442
 ]
}


data "azurerm_storage_account_blob_container_sas" "accountsas" {
  connection_string = azurerm_storage_account.webstore1353442.primary_connection_string
  container_name    = azurerm_storage_container.logs.name
  https_only        = true

  start  = "2023-07-15"
  expiry = "2023-07-16"

  permissions {
    read   = true
    add    = true
    create = false
    write  = true
    delete = true
    list   = true
  }

  cache_control       = "max-age=5"
  content_disposition = "inline"
  content_encoding    = "deflate"
  content_language    = "en-US"
  content_type        = "application/json"
}

output "sas" {
  value=nonsensitive("https://${azurerm_storage_account.webstore1353442.name}.blob.core.windows.net/${azurerm_storage_container.logs.name}${data.azurerm_storage_account_blob_container_sas.accountsas.sas}")
  }