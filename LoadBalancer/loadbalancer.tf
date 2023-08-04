resource "azurerm_public_ip" "loadip" {
  name                = "load-ip"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  allocation_method   = "Static"
  sku                 = "Standard"

  depends_on = [ 
    azurerm_resource_group.appgrp
  ]
}

resource "azurerm_lb" "appbalancer" {
  name                = "appbalancer"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  sku                 = "Standard"
  sku_tier            = "Regional"

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.loadip.id
  }

  depends_on = [ 
    azurerm_public_ip.loadip 
  ]
}

resource "azurerm_lb_backend_address_pool" "poolA" {
  loadbalancer_id = azurerm_lb.appbalancer.id
  name            = "PoolA"

  depends_on = [ 
    azurerm_lb.appbalancer
  ]
}

resource "azurerm_lb_backend_address_pool_address" "appvmaddress" {
  count                   = "appvm${count.index}"
  name                    = "example"
  backend_address_pool_id = data.azurerm_lb_backend_address_pool.poolA.id
  virtual_network_id      = data.azurerm_virtual_network.appnetwork.id
  ip_address              = azurerm_network_interface.appinterface[count.index].private_ip_address_allocation

  depends_on = [ 
    azurerm_lb_backend_address_pool.poolA, 
    azurerm_network_interface.appinterface
  ]
}

resource "azurerm_lb_probe" "probeA" {
  loadbalancer_id = azurerm_lb.appbalancer.id
  name            = "probeA"
  port            = 80
  protocol        = "Tcp" 

  depends_on = [ 
    azurerm_lb.appbalancer
  ]
}

resource "azurerm_lb_rule" "RuleA" {
  loadbalancer_id                = azurerm_lb.appbalancer.id
  name                           = "RuleA"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.poolA.id]

  depends_on = [ 
    azurerm_lb.appbalancer
  ]
}