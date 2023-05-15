terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.55.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "1.0.0"
    }
  }
}

# Configure Azure provider
provider "azurerm" {
  features {}
}

# Configure Databricks provider
provider "databricks" {
  host = azurerm_databricks_workspace.databricks_workspace.workspace_url
}

# Create resource group
resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

# Create Databricks workspace
resource "azurerm_databricks_workspace" "databricks_workspace" {
  location            = azurerm_resource_group.resource_group.location
  name                = "databricks-test-001"
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "standard"

  depends_on = [
    azurerm_resource_group.resource_group
  ]
}

# Create cluster
data "databricks_node_type" "smallest" {
  local_disk = true

  depends_on = [
    azurerm_databricks_workspace.databricks_workspace
  ]
}

data "databricks_spark_version" "latest_lts" {
  long_term_support = true

  depends_on = [
    azurerm_databricks_workspace.databricks_workspace
  ]
}

resource "databricks_cluster" "single_node" {
  cluster_name            = "Single Node"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 10

  spark_conf = {
    # Single-node
    "spark.databricks.cluster.profile" : "singleNode"
    "spark.master" : "local[*]"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
  }

  depends_on = [
    azurerm_databricks_workspace.databricks_workspace
  ]
}

# Create Notebook
resource "databricks_notebook" "notebook" {
  content_base64 = base64encode("print('Welcome to Databricks-Labs notebook')")
  path           = "/Shared/Demo/demo_example_notebook"
  language       = "PYTHON"

  depends_on = [
    databricks_cluster.single_node,
    azurerm_databricks_workspace.databricks_workspace
  ]
}