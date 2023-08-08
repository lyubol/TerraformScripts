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


resource "azurerm_windows_virtual_machine_scale_set" "appset" {  
  name                  = "appset"
  resource_group_name   = local.resource_group_name
  location              = local.resource_group_location
  sku                   = "Standard_D2s_v3"
  instances             = var.number_of_machines 
  admin_username        = "adminuser"
  admin_password        = data.azurerm_key_vault_secret.vmpassword.value
  upgrade_mode          = "Automatic"

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

  network_interface {
    name    = "scaleset-interface"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.subnetA.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.scalesetpool.id]
    }
  }

  depends_on = [
    azurerm_subnet.subnetA,
    azurerm_resource_group.appgrp,
    azurerm_lb_backend_address_pool.scalesetpool
  ]
}