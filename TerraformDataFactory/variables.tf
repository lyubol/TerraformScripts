variable "resource_group_name" {
  type          = string
  description   = "Name of resource group"
  default       = "default-grp"
}

variable "resource_group_location" {
    type        = string
    description = "Location of resource group"
    default     = "North Europe"
}

variable "datafactory_name" {
    type            = string
    description     = "Name of DataFactory resource"
    default         = "datafactory-ne-001"
}

variable "storage_account_name" {
    type            = string
    description     = "Name of storage account"
    default         = "datafactorystorageacc001"
}

variable "source_container_name" {
    type            = string
    description     = "Name of source container"
    default         = "source"
}

variable "destination_container_name" {
    type            = string
    description     = "Name of destination container"
    default         = "destination"
}

variable "key_vault_name" {
    type            = string
    description     = "Name of Key Vault"
    default         = "keyvaultne0013"
}
