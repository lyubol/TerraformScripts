resource "azurerm_virtual_network" "network" {
  for_each            = local.environments
  name                = "${each.key}-network"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  address_space       = [each.value]

  subnet {
    name           = "${each.key}subnet"
    address_prefix = cidrsubnet(each.value,8,0)
  }

  depends_on = [ 
    azurerm_resource_group.appgrp
 ]
}

resource "azurerm_network_security_group" "nsg" {
  for_each            = local.environments
  name                = "${each.key}-nsg"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "AllowRDP"
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
    azurerm_virtual_network.network
 ]
}

resource "azurerm_subnet_network_security_group_association" "nsg-link" {
  for_each                  = local.environments
  subnet_id                 = azurerm_virtual_network.network[each.key].subnet.*.id[0]
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
  
  depends_on = [ 
    azurerm_virtual_network.network,
    azurerm_network_security_group.nsg
 ]
}