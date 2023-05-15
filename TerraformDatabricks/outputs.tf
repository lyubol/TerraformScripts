output "resource_group_name" {
  value = azurerm_resource_group.resource_group.name
}

output "resource_group_location" {
  value = azurerm_resource_group.resource_group.location
}

output "databricks_host" {
  value = "https://${azurerm_databricks_workspace.databricks_workspace.workspace_url}/"
}

output "databricks_cluster" {
  value = "databricks_cluster.shared_autoscaling.cluster_name"
}