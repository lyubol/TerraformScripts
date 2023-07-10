# Define locals
locals {
  resource_group_name = "app-grp"
  resource_group_location = "North Europe"
}

resource "azurerm_resource_group" "appgrp" {
  name     = local.resource_group_name
  location = local.resource_group_location
}

# This section creates three storage accounts with the count index appended to the specified storage account name
resource "azurerm_storage_account" "appstore1457684" {
  count                    = 3
  name                     = "${count.index}appstore1457684"
  resource_group_name      = local.resource_group_name
  location                 = local.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  depends_on = [ 
    azurerm_resource_group.appgrp
 ]
}

# resource "azurerm_storage_account" "appstore1457684" {
#   name                     = "appstore1457684"
#   resource_group_name      = local.resource_group_name
#   location                 = local.resource_group_location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#   account_kind             = "StorageV2"

#   depends_on = [ 
#     azurerm_resource_group.appgrp
#  ]
# }

# # This section creates multiple containers within a storage account using count index
# resource "azurerm_storage_container" "data" {
#   count                 = 3
#   name                  = "data${count.index}"
#   storage_account_name  = azurerm_storage_account.appstore1457684.name
#   container_access_type = "private"

#   depends_on = [ 
#     azurerm_storage_account.appstore1457684
#   ]
# }