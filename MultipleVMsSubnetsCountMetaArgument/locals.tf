# define local variables
locals {
  resource_group_name = "app-grp"
  resource_group_location = "North Europe"
  virtual_network = {
    name = "app-network"
    address_space = "10.0.0.0/16"
  }
}