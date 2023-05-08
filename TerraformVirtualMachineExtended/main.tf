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
  features {}
}

# Define variables
variable "windows_vm_user_name" {
  type = string
  description = "Please, enter a user name for the windows virtual machine"
}

variable "windows_vm_password" {
  type = string
  description = "Please, enter a password for the windows virtual machine"
}

variable "storage_account_name" {
  type = string
  description = "Please, enter a name for the storage account"
}

# Define local variables
locals {
  resource_group_name = "app-grp"
  resource_group_location = "North Europe"
}

# Define data block to get info about existing resource
data "azurerm_subnet" "SubnetA" {
  name = "SubnetA"
  virtual_network_name = "app-network"
  resource_group_name = local.resource_group_name

  depends_on = [ 
     azurerm_virtual_network.app_network
   ]
}

# Create resource group
resource "azurerm_resource_group" "app_grp" {
  name = local.resource_group_name
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
    public_ip_address_id = azurerm_public_ip.app_public_ip.id
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
  admin_username      = var.windows_vm_user_name
  admin_password      = var.windows_vm_password
  availability_set_id = azurerm_availability_set.app_set.id
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
     azurerm_availability_set.app_set
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

# Create managed disk
resource "azurerm_managed_disk" "data_disk" {
  name                 = "data-disk"
  location             = local.resource_group_location
  resource_group_name  = local.resource_group_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "16"

  depends_on = [ 
     azurerm_resource_group.app_grp 
   ]
}

# Attach the data disk to the virtual machine
resource "azurerm_virtual_machine_data_disk_attachment" "disk_attach" {
  managed_disk_id    = azurerm_managed_disk.data_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.app_vm.id
  lun                = "10"
  caching            = "ReadWrite"

  depends_on = [ 
     azurerm_windows_virtual_machine.app_vm,
     azurerm_managed_disk.data_disk
   ]
}

# Create availability set
resource "azurerm_availability_set" "app_set" {
  name                = "app-set"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  platform_fault_domain_count = 3
  platform_update_domain_count = 3

  depends_on = [ 
     azurerm_resource_group.app_grp
   ]
}

# Create storage account
resource "azurerm_storage_account" "appstore" {
  name                     = var.storage_account_name
  resource_group_name      = local.resource_group_name
  location                 = local.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  depends_on = [ 
     azurerm_resource_group.app_grp
   ]
}

# Create a container within the storage account
resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = var.storage_account_name
  container_access_type = "blob"

  depends_on = [ 
      azurerm_storage_account.appstore
   ]
}

# Upload IIS Configuration script to the container
resource "azurerm_storage_blob" "IIS_config" {
  name                   = "IIS_Config.ps1"
  storage_account_name   = var.storage_account_name
  storage_container_name = azurerm_storage_container.data.name
  type                   = "Block"
  source                 = "IIS_Config.ps1"

  depends_on = [ 
      azurerm_storage_container.data
   ]
}

resource "azurerm_virtual_machine_extension" "vm_extension" {
  name                 = "appvm-extension"
  virtual_machine_id   = azurerm_windows_virtual_machine.app_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  depends_on = [ 
      azurerm_storage_blob.IIS_config
   ]

  settings = <<SETTINGS
 {
  "fileUris": ["https://${azurerm_storage_account.appstore.name}.blob.core.windows.net/data/IIS_Config.ps1"], "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file IIS_Config.ps1"
 }
SETTINGS
}