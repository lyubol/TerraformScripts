# define local variables
locals {
  resource_group_name = "app-grp"
  resource_group_location = "North Europe"
  environments = {
    staging = "10.0.0.0/16"
    test = "10.1.0.0/16"
  }
}