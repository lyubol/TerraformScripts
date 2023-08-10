# Get Key Vault secrets
data "azurerm_key_vault" "newkeyvault156657" {
  name                = "newkeyvault156657"
  resource_group_name = "new-grp"
}

data "azurerm_key_vault_secret" "vmpassword" {
  name         = "vmpassword"
  key_vault_id = data.azurerm_key_vault.newkeyvault156657.id
}

resource "azurerm_network_interface" "interface" {
  for_each            = local.environments
  name                = "${each.key}-interface"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_virtual_network.network[each.key].subnet.*.id[0]
    private_ip_address_allocation = "Dynamic"    
    public_ip_address_id = azurerm_public_ip.ip[each.key].id
  }

  depends_on = [
    azurerm_virtual_network.network
  ]
}

resource "azurerm_public_ip" "ip" {
 for_each             = local.environments
  name                = "${each.key}-ip"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location  
  allocation_method   = "Dynamic"
  depends_on = [
    azurerm_resource_group.appgrp
  ]
}


resource "azurerm_windows_virtual_machine" "vm" {
  for_each            = local.environments
  name                = "${each.key}vm"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = data.azurerm_key_vault_secret.vmpassword.value     
    network_interface_ids = [
    azurerm_network_interface.interface[each.key].id,
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
    azurerm_virtual_network.network,
    azurerm_network_interface.interface
  ]
}