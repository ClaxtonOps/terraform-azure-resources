resource "azurerm_network_security_group" "frontend" {
  name                = "frontendNSG"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  dynamic "security_rule" {
    for_each = local.app_gateway_nsg_rules

    content {
      name                       = try(security_rule.value.name, null)
      priority                   = try(security_rule.value.priority, null)
      direction                  = try(security_rule.value.direction, null)
      access                     = try(security_rule.value.access, null)
      protocol                   = try(security_rule.value.protocol, "Tcp")
      source_port_range          = try(security_rule.value.source_port_range, null)
      destination_port_range     = try(security_rule.value.destination_port_range, null)
      source_address_prefix      = try(security_rule.value.source_address_prefix, null)
      destination_address_prefix = try(security_rule.value.destination_address_prefix, null)
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "frontend_assoc" {
  subnet_id                 = data.azurerm_subnet.subnets["frontend"].id
  network_security_group_id = azurerm_network_security_group.frontend.id
}


resource "azurerm_network_security_group" "backend" {
  name                = "backendNSG"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  dynamic "security_rule" {
    for_each = local.app_server_nsg_rules

    content {
      name                       = try(security_rule.value.name, null)
      priority                   = try(security_rule.value.priority, null)
      direction                  = try(security_rule.value.direction, null)
      access                     = try(security_rule.value.access, null)
      protocol                   = try(security_rule.value.protocol, "Tcp")
      source_port_range          = try(security_rule.value.source_port_range, null)
      destination_port_range     = try(security_rule.value.destination_port_range, null)
      source_address_prefix      = try(security_rule.value.source_address_prefix, null)
      destination_address_prefix = try(security_rule.value.destination_address_prefix, null)
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "backend_assoc" {
  subnet_id                 = data.azurerm_subnet.subnets["backend"].id
  network_security_group_id = azurerm_network_security_group.backend.id
}

resource "azurerm_network_security_group" "database" {
  name                = "databaseNSG"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  dynamic "security_rule" {
    for_each = local.database_nsg_rules

    content {
      name                       = try(security_rule.value.name, null)
      priority                   = try(security_rule.value.priority, null)
      direction                  = try(security_rule.value.direction, null)
      access                     = try(security_rule.value.access, null)
      protocol                   = try(security_rule.value.protocol, "Tcp")
      source_port_range          = try(security_rule.value.source_port_range, null)
      destination_port_range     = try(security_rule.value.destination_port_range, null)
      source_address_prefix      = try(security_rule.value.source_address_prefix, null)
      destination_address_prefix = try(security_rule.value.destination_address_prefix, null)
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "database_assoc" {
  subnet_id                 = data.azurerm_subnet.subnets["database"].id
  network_security_group_id = azurerm_network_security_group.database.id
}