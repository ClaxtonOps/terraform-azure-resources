provider "azurerm" {
  features {}
}


data "azurerm_resource_group" "rg" {
  name = "ClaxtonLab-RG"
}

data "azurerm_virtual_network" "vnet" {
  name                = "ClaxtonLab-VNET"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "subnets" {
  for_each = { for name in var.subnet_names : name => name }

  name                 = each.value
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

locals {
  prefix = "claxtonLab"

  app_gateway_nsg_rules = {
    inbound_http = {
      name                       = "allowInboundHTTP-AppGW"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = var.port_http
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    inbound_https = {
      name                       = "allowInboundHTTPS-AppGW"
      priority                   = 101
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = var.port_https
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    inbound_appgw = {
      name                       = "allowInboundGW"
      priority                   = 102
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "65200-65535"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    outbound_vm_subnet = {
      name                       = "allowOutboundToVMSubnet"
      priority                   = 200
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80-443"
      source_address_prefix      = "*"
      destination_address_prefix = data.azurerm_subnet.subnets["backend"].address_prefix
    }
  }
  app_server_nsg_rules = {
    inbound_ssh = {
      name                       = "allowInboundSSH-AppServer"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    inbound_https = {
      name                       = "allowInboundHTTPs-AppServer"
      priority                   = 101
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = var.port_https
      source_address_prefix      = data.azurerm_subnet.subnets["frontend"].address_prefix
      destination_address_prefix = "*"
    },
    inbound_http = {
      name                       = "allowInboundHTTP-Appserver"
      priority                   = 102
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = var.port_http
      source_address_prefix      = data.azurerm_subnet.subnets["frontend"].address_prefix
      destination_address_prefix = "*"
    },
    outbound_db_subnet = {
      name                       = "allowOutboundToDBSubnet"
      priority                   = 200
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = var.port_db
      source_address_prefix      = "*"
      destination_address_prefix = data.azurerm_subnet.subnets["database"].address_prefix # Prefixo da subnet que contém a aplicação.
    }

  }
  database_nsg_rules = {
    inbound_db = {
      name                       = "allowVMtoDB"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = var.port_db                                                   # Porta do banco de dados (ex: 5432 para PostgreSQL)
      source_address_prefix      = data.azurerm_subnet.subnets["backend"].address_prefix  # Prefixo de endereço da sub-rede da VM
      destination_address_prefix = data.azurerm_subnet.subnets["database"].address_prefix # Prefixo de endereço da sub-rede do banco de dados
    }
  }
}
