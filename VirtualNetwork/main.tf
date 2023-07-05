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
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  address_space       = [local.virtual_network.address_space]

  depends_on = [
    azurerm_resource_group.appgrp
  ]
}

resource "azurerm_subnet" "subnetA" {
  name                 = local.subnets[0].name
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes     = [local.subnets[0].address_prefix]

  depends_on = [
    azurerm_virtual_network.appnetwork
  ]
}

resource "azurerm_subnet" "subnetB" {
  name                 = local.subnets[1].name
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes     = [local.subnets[1].address_prefix]

  depends_on = [
    azurerm_virtual_network.appnetwork
  ]
}

resource "azurerm_network_interface" "appinterface" {
  name                = "appinterface"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.appip.id
  }

  depends_on = [ 
    azurerm_subnet.subnetA 
  ]
}

resource "azurerm_public_ip" "appip" {
  name                = "app-ip"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  allocation_method   = "Static"

  depends_on = [ 
    azurerm_resource_group.appgrp
  ]
}

resource "azurerm_network_security_group" "appnsg" {
  name                = "app-nsg"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "test123"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  depends_on = [ 
    azurerm_resource_group.appgrp
 ]
}

resource "azurerm_subnet_network_security_group_association" "appnsglink" {
  subnet_id                 = azurerm_subnet.subnetA.id
  network_security_group_id = azurerm_network_security_group.appnsg.id
}