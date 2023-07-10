# Define locals
locals {
  resource_group_name = "app-grp"
  resource_group_location = "North Europe"
}

resource "azurerm_resource_group" "appgrp" {
  name     = local.resource_group_name
  location = local.resource_group_location
}

resource "azurerm_storage_account" "appstore1457684" {
  name                     = "appstore1457684"
  resource_group_name      = local.resource_group_name
  location                 = local.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  depends_on = [ 
    azurerm_resource_group.appgrp
 ]
}

# This section creates a container for each value within the specified for each set
resource "azurerm_storage_container" "data" {
  for_each              = toset(["data", "files", "documents"])
  name                  = each.key
  storage_account_name  = azurerm_storage_account.appstore1457684.name
  container_access_type = "blob"

  depends_on = [ 
    azurerm_storage_account.appstore1457684
  ]
}

# Copy local files to the 'data' container using a for each
resource "azurerm_storage_blob" "files" {
  for_each = {
    sample1 = "C:\\Users\\L_L\\Desktop\\Learning\\Terraform\\02.StorageAccountsAndVMs_Enhanced\\MultipleStorageAccounts\\FilesToUpload\\tmp1\\sample1.txt"
    sample2 = "C:\\Users\\L_L\\Desktop\\Learning\\Terraform\\02.StorageAccountsAndVMs_Enhanced\\MultipleStorageAccounts\\FilesToUpload\\tmp2\\sample2.txt"
    sample3 = "C:\\Users\\L_L\\Desktop\\Learning\\Terraform\\02.StorageAccountsAndVMs_Enhanced\\MultipleStorageAccounts\\FilesToUpload\\tmp3\\sample3.txt"
  }
  name                   = "${each.key}.txt"
  storage_account_name   = azurerm_storage_account.appstore1457684.name
  storage_container_name = "data"
  type                   = "Block"
  source                 = each.value

  depends_on = [ 
    azurerm_storage_container.data
  ]
}