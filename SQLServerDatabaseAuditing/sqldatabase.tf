data "azurerm_key_vault" "newkeyvault156657" {
  name                = "newkeyvault156657"
  resource_group_name = "new-grp"
}

data "azurerm_key_vault_secret" "sqladminpassword" {
  name         = "sqladmin-password"
  key_vault_id = data.azurerm_key_vault.newkeyvault156657.id
}

resource "azurerm_mssql_server" "sqlserver" {
  name                         = "sqlserver134779"
  resource_group_name          = local.resource_group_name
  location                     = local.resource_group_location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = data.azurerm_key_vault_secret.sqladminpassword.value
  minimum_tls_version          = "1.2"

  depends_on = [ 
    azurerm_resource_group.appgrp
  ]
}

resource "azurerm_mssql_database" "appdb" {
  name           = "appdb"
  server_id      = azurerm_mssql_server.sqlserver.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  sku_name       = "S0"

  depends_on = [ 
    azurerm_mssql_server.sqlserver
  ]
}

resource "azurerm_mssql_firewall_rule" "allowmyclient" {
  name             = "AllowClientIP"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "64.34.146.124"
  end_ip_address   = "64.34.146.124"

depends_on = [ 
    azurerm_mssql_server.sqlserver
]
}