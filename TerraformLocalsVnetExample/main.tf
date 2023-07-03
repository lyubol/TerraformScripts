# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.10.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
    features {}
}

# define local variables
locals {
  resource_group_name = "app-grp"
  resource_group_location = "North Europe"
  virtual_network = {
    name = "app-network"
    address_space = "10.0.0.0/16"
  }
  subnets = [
    {
        name = "subnetA"
        address_prefix = "10.0.0.0/24"
    },
    {
        name = "subnetB"
        address_prefix = "10.0.1.0/24"
    }
  ]
}

resource "azurerm_resource_group" "appgrp" {
  name     = local.resource_group_name
  location = local.resource_group_location
}

resource "azurerm_virtual_network" "appnetwork" {
  name                = local.virtual_network.name
  location            = azurerm_resource_group.appgrp.location
  resource_group_name = azurerm_resource_group.appgrp.name
  address_space       = [local.virtual_network.address_space]

  subnet {
    name           = local.subnets[0].name
    address_prefix = local.subnets[0].address_prefix
  }

  subnet {
    name           = local.subnets[0].name
    address_prefix = local.subnets[0].address_prefix
  }

  depends_on = [
    azurerm_resource_group.appgrp
  ]
}