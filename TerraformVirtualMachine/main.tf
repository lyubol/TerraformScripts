terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.55.0"
    }
  }
}

# Provide Azure connection details
provider "azurerm" {
  features {}
}

# Define local variables
locals {
  resource_group_name     = "app-grp"
  resource_group_location = "North Europe"
}

# Define data block to get info about existing resource
data "azurerm_subnet" "SubnetA" {
  name                 = "SubnetA"
  virtual_network_name = "app-network"
  resource_group_name  = local.resource_group_name

  depends_on = [
    azurerm_virtual_network.app_network
  ]
}

data "azurerm_client_config" "current" {}

# Create resource group
resource "azurerm_resource_group" "app_grp" {
  name     = local.resource_group_name
  location = local.resource_group_location
}

# Create virtual network and subnet
resource "azurerm_virtual_network" "app_network" {
  name                = "app-network"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  address_space       = ["10.0.0.0/16"]

  subnet {
    name           = "SubnetA"
    address_prefix = "10.0.1.0/24"
  }

  depends_on = [
    azurerm_resource_group.app_grp
  ]
}

# Create network interface
resource "azurerm_network_interface" "app_interface" {
  name                = "app-interface"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app_public_ip.id
  }

  depends_on = [
    azurerm_virtual_network.app_network,
    azurerm_public_ip.app_public_ip
  ]
}

# Create windows virtual machine
resource "azurerm_windows_virtual_machine" "app_vm" {
  name                = "appvm"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  size                = "Standard_D2s_v3"
  admin_username      = "demousr"
  admin_password      = azurerm_key_vault_secret.vmpassword.value
  network_interface_ids = [
    azurerm_network_interface.app_interface.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.app_interface,
    azurerm_key_vault_secret.vmpassword
  ]
}

# Create public ip address
resource "azurerm_public_ip" "app_public_ip" {
  name                = "app-public-ip"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  allocation_method   = "Static"

  depends_on = [
    azurerm_resource_group.app_grp
  ]
}

# Create key vault
resource "azurerm_key_vault" "app_vault" {
  name                        = "lirkovvault13"
  location                    = local.resource_group_location
  resource_group_name         = local.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Backup", "Purge", "Recover", "Restore",
    ]

    storage_permissions = [
      "Get",
    ]
  }

  depends_on = [ 
      azurerm_resource_group.app_grp
   ]
}

# Create a secret in the key vault
resource "azurerm_key_vault_secret" "vmpassword" {
  name         = "vmpassword"
  value        = "Azure123"
  key_vault_id = azurerm_key_vault.app_vault.id
  depends_on = [ 
      azurerm_key_vault.app_vault
   ]
}