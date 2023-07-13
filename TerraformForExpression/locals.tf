# define local variables
locals {
  resource_group_name = "app-grp"
  resource_group_location = "North Europe"
  common_tags = {
    "environment" = "staging"
    "tier" = 3
    "department" = "IT"
  }
}