# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.8.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "appgrp" {
  name     = "app-grp"
  location = "North Europe"
}

resource "azurerm_storage_account" "appstorage1317a" {
  name                     = "appstorage1317a"
  resource_group_name      = azurerm_resource_group.appgrp.name
  location                 = azurerm_resource_group.appgrp.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2" 
  depends_on = [
    azurerm_resource_group.appgrp
  ]
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.appstorage1317a.name
  container_access_type = "blob"
  depends_on = [
    azurerm_storage_account.appstorage1317a
  ]
}

resource "azurerm_storage_blob" "maintf" {
  name                   = "main.tf"
  storage_account_name   = azurerm_storage_account.appstorage1317a.name
  storage_container_name = azurerm_storage_container.data.name
  type                   = "Block"
  source                 = "main.tf"
  depends_on = [
    azurerm_storage_container.data
  ]
}