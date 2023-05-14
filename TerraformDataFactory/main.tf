#################################################################
### AZURE RESOURCE GROUP
#################################################################
resource "azurerm_resource_group" "datafactory_grp" {
  location  = var.resource_group_location
  name      = var.resource_group_name
}

data "azurerm_client_config" "current" {
}

data "azurerm_storage_account_sas" "sas_key" {
  connection_string = azurerm_storage_account.adls.primary_connection_string
  https_only        = true
  signed_version    = "2017-07-29"

  resource_types {
    service   = true
    container = false
    object    = false
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = "2023-05-14T08:00:00Z"
  expiry = "2023-05-21T08:00:00Z"

  permissions {
    read    = true
    write   = true
    delete  = false
    list    = false
    add     = true
    create  = true
    update  = false
    process = false
    tag     = false
    filter  = false
  }

  depends_on = [ 
      azurerm_resource_group.datafactory_grp,
      azurerm_storage_account.adls,
      azurerm_storage_container.source_container,
      azurerm_storage_container.destination_container
   ]
}

#################################################################
### AZURE DATA FACTORY 
#################################################################
resource "azurerm_data_factory" "datafactory" {
    location                = azurerm_resource_group.datafactory_grp.location
    name                    = var.datafactory_name
    resource_group_name     = var.resource_group_name

    depends_on = [ 
        azurerm_resource_group.datafactory_grp
     ]
}

resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.datafactory.principal_id

  depends_on = [ 
      azurerm_resource_group.datafactory_grp,
      azurerm_data_factory.datafactory
   ]
}

# Linked service - Key Vault
resource "azurerm_data_factory_linked_service_key_vault" "linked_service_key_vault" {
  name            = "linkkv"
  data_factory_id = azurerm_data_factory.datafactory.id
  key_vault_id    = azurerm_key_vault.key_vault.id

  depends_on = [ 
      azurerm_resource_group.datafactory_grp,
      azurerm_data_factory.datafactory,
      azurerm_key_vault.key_vault
   ]
}

# Linked service - Azure Data Lake Storage
resource "azurerm_data_factory_linked_service_azure_blob_storage" "linked_service_storage_account" {
  name            = "linkadls"
  data_factory_id = azurerm_data_factory.datafactory.id

  sas_uri = "https://${var.storage_account_name}.blob.core.windows.net"
  key_vault_sas_token {
    linked_service_name = azurerm_data_factory_linked_service_key_vault.linked_service_key_vault.name
    secret_name         = "secret"
  }

  depends_on = [ 
      azurerm_resource_group.datafactory_grp,
      azurerm_data_factory.datafactory,
      azurerm_key_vault.key_vault
   ]
}

#################################################################
### AZURE STORAGE ACCOUNT
#################################################################
resource "azurerm_storage_account" "adls" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"

  depends_on = [ 
      azurerm_resource_group.datafactory_grp
   ]
}

# Create storage account container
resource "azurerm_storage_container" "source_container" {
  name                  = var.source_container_name
  storage_account_name  = var.storage_account_name
  container_access_type = "private"

  depends_on = [ 
      azurerm_resource_group.datafactory_grp,
      azurerm_storage_account.adls
   ]
}

# Create storage account container
resource "azurerm_storage_container" "destination_container" {
  name                  = var.destination_container_name
  storage_account_name  = var.storage_account_name
  container_access_type = "private"

  depends_on = [ 
      azurerm_resource_group.datafactory_grp,
      azurerm_storage_account.adls
   ]
}

#################################################################
### AZURE KEY VAULT
#################################################################
resource "azurerm_key_vault" "key_vault" {
  name                  = var.key_vault_name
  location              = var.resource_group_location
  resource_group_name   = var.resource_group_name
  tenant_id             = data.azurerm_client_config.current.tenant_id
  sku_name              = "standard"
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    key_permissions = [
      "Get",
    ]
    secret_permissions = [
      "Get", "List", "Set", "Delete", "Backup", "Purge", "Recover", "Restore",
    ]
    storage_permissions = [
      "Get",
    ]
  }

  depends_on = [ 
      azurerm_resource_group.datafactory_grp
   ]
}

# Create secret
resource "azurerm_key_vault_secret" "test_secret" {
  name = "testsecret"
  value = "Azure123"
  key_vault_id = azurerm_key_vault.key_vault.id
  
  depends_on = [ 
      azurerm_resource_group.datafactory_grp,
      azurerm_key_vault.key_vault
   ]
}

# Create secret
resource "azurerm_key_vault_secret" "adls_sas_secret" {
  name = "adls-sas"
  value = data.azurerm_storage_account_sas.sas_key.sas
  key_vault_id = azurerm_key_vault.key_vault.id
  
  depends_on = [ 
      azurerm_resource_group.datafactory_grp,
      azurerm_key_vault.key_vault
   ]
}