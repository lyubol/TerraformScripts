resource "azurerm_network_interface" "appinterface" {
  count               = var.number_of_machines
  name                = "appinterface${count.index}"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnets[count.index].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.appip.id
  }

  depends_on = [ 
    azurerm_subnet.subnets,
    azurerm_public_ip.appip
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

data "azurerm_key_vault" "newkeyvault156657" {
  name                = "newkeyvault156657"
  resource_group_name = "new-grp"
}

data "azurerm_key_vault_secret" "vmpassword" {
  name         = "vmpassword"
  key_vault_id = data.azurerm_key_vault.newkeyvault156657.id
}

resource "azurerm_windows_virtual_machine" "appvm" {
  count                 = var.number_of_machines
  name                  = "appvm${count.index}"
  resource_group_name   = local.resource_group_name
  location              = local.resource_group_location
  size                  = "Standard_Ds1_v2"
  admin_username        = "adminuser"
  admin_password        = data.azurerm_key_vault_secret.vmpassword.value
  network_interface_ids = [
    azurerm_network_interface.appinterface[count.index].id
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
    azurerm_network_interface.appinterface,
    azurerm_resource_group.appgrp 
  ]
}