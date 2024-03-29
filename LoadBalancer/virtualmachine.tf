# Get Key Vault secrets
data "azurerm_key_vault" "newkeyvault156657" {
  name                = "newkeyvault156657"
  resource_group_name = "new-grp"
}

data "azurerm_key_vault_secret" "vmpassword" {
  name         = "vmpassword"
  key_vault_id = data.azurerm_key_vault.newkeyvault156657.id
}

data "azurerm_key_vault_secret" "sqladminpassword" {
  name         = "sqladmin-password"
  key_vault_id = data.azurerm_key_vault.newkeyvault156657.id
}


resource "azurerm_network_interface" "appinterface" {
  count               = var.number_of_machines
  name                = "appinterface${count.index}"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnetA.id
    private_ip_address_allocation = "Dynamic"    
  }

  depends_on = [
    azurerm_virtual_network.appnetwork
  ]
}

resource "azurerm_windows_virtual_machine" "appvm" {  
  count                 = var.number_of_machines
  name                  = "appvm${count.index}"
  resource_group_name   = local.resource_group_name
  location              = local.resource_group_location
  size                  = "Standard_D2s_v3"
  admin_username        = "adminuser"
  admin_password        = data.azurerm_key_vault_secret.vmpassword.value
  availability_set_id   = azurerm_availability_set.appset.id
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
    azurerm_virtual_network.appnetwork,
    azurerm_network_interface.appinterface,
    azurerm_availability_set.appset
  ]
}