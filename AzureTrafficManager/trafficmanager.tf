resource "azurerm_traffic_manager_profile" "app-profile" {
  name                   = "app-profile1013"
  resource_group_name    = local.resource_group_name
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "app-profile1013"
    ttl           = 100
  }

  monitor_config {
    protocol                     = "HTTPS"
    port                         = 443
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }

  depends_on = [ 
    azurerm_resource_group.appgrp
  ]
}

resource "azurerm_traffic_manager_azure_endpoint" "primaryendpoint" {
  name               = "primaryendpoint"
  profile_id         = azurerm_traffic_manager_profile.app-profile.id
  priority           = 1 
  weight             = 100
  target_resource_id = azurerm_windows_web_app.primaryapp.id
  
  custom_header {
    name = "host"
    value = "${azurerm_windows_web_app.primaryapp.name}.azurewebsites.net"
  }

  depends_on = [ 
    azurerm_windows_web_app.primaryapp
 ]
}

resource "azurerm_traffic_manager_azure_endpoint" "secondaryendpoint" {
  name               = "secondaryendpoint"
  profile_id         = azurerm_traffic_manager_profile.app-profile.id
  priority           = 2 
  weight             = 100
  target_resource_id = azurerm_windows_web_app.secondaryapp.id
  
  custom_header {
    name = "host"
    value = "${azurerm_windows_web_app.secondaryapp.name}.azurewebsites.net"
  }

  depends_on = [ 
    azurerm_windows_web_app.secondaryapp
 ]
}