data "azurerm_resource_group" "rg" {
  name = "ClaxtonLab-RG"
}

data "azurerm_virtual_network" "vnet" {
  name                = "ClaxtonLab-VNET"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "frontend" {
  name                 = "frontend"
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

data "azurerm_public_ip" "appgateway" {
  name                = "ApplicationGateway-PIP"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_key_vault" "keyvault" {
  name                = "Vault-claxtonops-nLzje"
  resource_group_name = data.azurerm_resource_group.rg.name

}

data "azurerm_key_vault_certificate" "ssl_certificates" {
  name         = "claxtonopslab"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

data "azurerm_user_assigned_identity" "uai" {
  name                = "Identity-KV-AppGw"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_network_interface" "nic" {
  name                = "ClaxtonLab-NIC"
  resource_group_name = data.azurerm_resource_group.rg.name
}

locals {
  prefix = "ClaxtonLab"
  sku    = "Standard_v2"
  #zones  = ["2"]  #"2", "3"] #Availability zones to spread the Application Gateway over. They are also only supported for v2 SKUs.
  capacity = {
    min = 1 #Minimum capacity for autoscaling. Accepted values are in the range 0 to 100.
    max = 3 #Maximum capacity for autoscaling. Accepted values are in the range 2 to 125.
  }

  backend_address_pool_name      = "${local.prefix}-BackendAddressPoolName"
  frontend_port_name             = "${local.prefix}-FrontPortName"
  frontend_ip_configuration_name = "${local.prefix}-FrontIpConfName"
  http_setting_name              = "${local.prefix}-Http-HttpsSettingName"
  listener_name                  = "${local.prefix}-httplstn"
  request_routing_rule_name      = "${local.prefix}-RequestRoutingName"

  frontend_ports = {
    Http = {
      name = "http"
      port = 80
    },
    Https = {
      name = "https"
      port = 443
    }
  }

  key_vault_certificates = [
    {
      name      = data.azurerm_key_vault_certificate.ssl_certificates.name
      secret_id = data.azurerm_key_vault_certificate.ssl_certificates.secret_id
    }
  ]

  common_tags = {
    Environment = "Dev"
    Owner       = "Paulo H"
    Department  = "DevOps"
  }
}