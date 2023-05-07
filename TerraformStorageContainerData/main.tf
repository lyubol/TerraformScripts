terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.55.0"
    }
  }
}

# Provide Azure connection details
provider "azurerm" {
  subscription_id = ""
  client_id = ""
  client_secret = ""
  tenant_id = ""
  features {}
}

# Define variables
variable "storage_account_name" {
  type                             = string
  description                      = "Please enter the storage account name"
}

# Define local variables
locals {
  resource_group_name              = "app-grp"
  resource_group_location          = "North Europe"
}

# Create resource group
resource "azurerm_resource_group" "app_grp" {
  name                              = local.resource_group_name
  location                          = local.resource_group_location
}

# Create storage account
resource "azurerm_storage_account" "storage_account" {
  name                              = var.storage_account_name
  resource_group_name               = local.resource_group_name
  location                          = local.resource_group_location
  account_tier                      = "Standard"
  account_replication_type          = "LRS"
  allow_nested_items_to_be_public   = true
  depends_on = [ 
      azurerm_resource_group.app_grp
   ]
}

# Create container
resource "azurerm_storage_container" "data" {
  name                              = "data"
  storage_account_name              = var.storage_account_name
  container_access_type             = "blob"
  depends_on = [ 
      azurerm_storage_account.storage_account
   ]
}

# Upload local file to the container
resource "azurerm_storage_blob" "drinks" {
  name                              = "drinks.csv"
  storage_account_name              = var.storage_account_name
  storage_container_name            = azurerm_storage_container.data.name
  type                              = "Block"
  source                            = "drinks.csv"
  depends_on = [ 
      azurerm_storage_container.data
   ]
}