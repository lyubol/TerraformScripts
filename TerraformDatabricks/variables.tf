variable "resource_group_name" {
  type        = string
  description = "Name of resource group"
  default     = "default-grp"
}

variable "resource_group_location" {
  type        = string
  description = "Location of resource group"
  default     = "North Europe"
}

variable "databricks_workspace_name" {
  type        = string
  description = "Databricks workspace name"
  default     = "databricks-001"
}

variable "databricks_cluster_name" {
  type        = string
  description = "Databricks cluster name"
  default     = "cluster-001"
}

variable "databricks_sku" {
  type        = string
  description = "Databricks resource sku"
  default     = "standard"
}