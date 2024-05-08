data "azurerm_resource_group" "rg" {
  name = "ClaxtonLab-RG"
}

resource "azurerm_virtual_network" "main" {
  name          = "${local.prefix}-VNET"
  address_space = try(local.address_space, null)

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  dynamic "subnet" {
    for_each = local.vnetSubnets

    content {
      name           = try(subnet.key, null)
      address_prefix = try(subnet.value.address_prefix, null)
      #security_group = try(subnet.value.security_group, null)
    }
  }
  tags = local.common_tags

}

resource "azurerm_route_table" "dynamic_route_table" {
  for_each = local.routes

  name = try(each.key, null)

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  route {
    name           = try(each.key, null)
    address_prefix = try(each.value.address_prefix, null)
    next_hop_type  = try(each.value.next_hop_type, "VnetLocal")
  }
    tags = local.common_tags

}

resource "azurerm_subnet_route_table_association" "subnet_association" {
  for_each = local.routes

  subnet_id      = try(each.value.subnet_id, null)
  route_table_id = azurerm_route_table.dynamic_route_table[each.key].id
}

/*
resource "azurerm_subnet" "this" {
  for_each = local.vnetSubnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = [each.value.address_prefix]
}
*/

resource "azurerm_public_ip" "pip" {
  for_each = {
    for key, value in local.vnetSubnets : key => value if contains(["backend", "frontend", "AzureBastionSubnet"], key)
  }

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  name = lookup({
    "backend"            = "NatGateway-PIP",
    "frontend"           = "ApplicationGateway-PIP",
    "AzureBastionSubnet" = "bastion-PIP",
  }, each.key, "${each.key}-PIP")

  allocation_method = "Static"
  sku               = try(local.sku, "Standard")

  tags = local.common_tags
}

resource "azurerm_bastion_host" "bastion" {
  name = "${local.prefix}-Bastion"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  sku               = try(local.sku, "Standard")
  tunneling_enabled = true

  ip_configuration {
    name                 = "configuration"
    subnet_id            = tolist(azurerm_virtual_network.main.subnet)[3].id
    public_ip_address_id = azurerm_public_ip.pip["AzureBastionSubnet"].id
  }
    tags = local.common_tags
}

resource "azurerm_nat_gateway" "nat" {
  name = "${local.prefix}-NAT"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  sku_name                = try(local.sku, "Standard")
  idle_timeout_in_minutes = 10

  tags = local.common_tags
}

resource "azurerm_nat_gateway_public_ip_association" "nat_pip" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.pip["backend"].id
}

resource "azurerm_subnet_nat_gateway_association" "nat_assc_subnet" {
  subnet_id      = try(tolist(azurerm_virtual_network.main.subnet)[0].id, null)
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

resource "azurerm_network_interface" "nic" {
  name = "${local.prefix}-NIC"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  ip_configuration {
    name                          = try("${local.prefix}-NIC-ip_configuration", "NIC")
    subnet_id                     = try(tolist(azurerm_virtual_network.main.subnet)[0].id, null)
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.common_tags
}