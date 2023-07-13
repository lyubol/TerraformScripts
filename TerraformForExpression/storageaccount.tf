resource "azurerm_storage_account" "vmstore135344" {
  name                     = join("", [lower("${var.storage_account_name}"), "${substr(random_uuid.storageaccountidentifier.result, 0, 8)}"])
  location                 = local.resource_group_location
  resource_group_name      = local.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  depends_on = [
    azurerm_resource_group.appgrp,
    random_uuid.storageaccountidentifier
  ]

  tags = {
    for name, value in local.common_tags: name=>"${value}"
  }
}