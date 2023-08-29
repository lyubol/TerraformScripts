resource "azurerm_resource_group" "resource_group" {
  name     = "tf-workspaces-${terraform.workspace}"
  location = "North Europe"
}

resource "azurerm_storage_account" "storage_dev" {
  name                     = "tfwrksptst0347121${terraform.workspace}"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "${terraform.workspace}"
  }
}