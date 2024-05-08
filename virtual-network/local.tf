provider "azurerm" {
  features {}
}


locals {
  prefix        = "ClaxtonLab"
  address_space = ["192.168.0.0/16"]
  sku           = "Standard"

  vnetSubnets = {
    "backend" = {
      address_prefix = "192.168.10.0/24"
      #security_group = azurerm_network_security_group.backend.id
    }
    "frontend" = {
      address_prefix = "192.168.11.0/24"
      #security_group = azurerm_network_security_group.frontend.id
    }
    "database" = {
      address_prefix = "192.168.12.0/24"
      #security_group = azurerm_network_security_group.database.id
    }
    "AzureBastionSubnet" = {
      address_prefix = "192.168.20.0/27"
    }
  }

  routes = {
    "frontend" = {
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
      subnet_id      = tolist(azurerm_virtual_network.main.subnet)[1].id
    }
    "backend" = {
      address_prefix = "192.168.0.0/16"
      next_hop_type  = "VnetLocal"
      subnet_id      = tolist(azurerm_virtual_network.main.subnet)[0].id

    }
    "database" = {
      address_prefix = "192.168.0.0/16"
      next_hop_type  = "VnetLocal"
      subnet_id      = tolist(azurerm_virtual_network.main.subnet)[2].id

    }
  }


  common_tags = {
    Environment = "Dev"
    Owner       = "Paulo H"
    Department  = "DevOps"
  }

}