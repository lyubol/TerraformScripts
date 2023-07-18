resource "azurerm_service_plan" "companyplan" {
  name                = "companyplan"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  os_type             = "Windows"
  sku_name            = "S1"

  depends_on = [ 
    azurerm_resource_group.appgrp
 ]
}

resource "azurerm_windows_web_app" "companyapp100" {
  name                = "companyapp113"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  service_plan_id     = azurerm_service_plan.companyplan.id

  site_config {
    application_stack {
      current_stack = "dotnet"
      dotnet_version = "v6.0"
    }
  }

  logs {
      detailed_error_messages = true
    http_logs {    
      azure_blob_storage {        
        retention_in_days=7   
        sas_url =  "https://${azurerm_storage_account.webstore1353442.name}.blob.core.windows.net/${azurerm_storage_container.logs.name}${data.azurerm_storage_account_blob_container_sas.accountsas.sas}"
        }
      }
    }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.appinsights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.appinsights.connection_string
    }

  depends_on = [ 
    azurerm_service_plan.companyplan
 ]
}

# resource "azurerm_app_service_source_control" "appservice_sourcecontrol" {
#   app_id                 = azurerm_windows_web_app.companyapp100.id
#   repo_url               = "https://github.com/lyubol/gitapp"
#   branch                 = "master"
#   use_manual_integration = true

#   depends_on = [ 
#     azurerm_windows_web_app.companyapp100
#  ]
# }