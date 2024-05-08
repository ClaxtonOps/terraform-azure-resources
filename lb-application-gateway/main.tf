provider "azurerm" {
  features {}
}


resource "azurerm_application_gateway" "network" {
  name = try("${local.prefix}-AppGateway", null)

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  enable_http2 = true
  #zones        = try(local.zones, null)

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.uai.id]
  }

  sku {
    name = try(local.sku, null)
    tier = try(local.sku, null)
  }

  autoscale_configuration {
    min_capacity = try(local.capacity.min, null)
    max_capacity = try(local.capacity.max, null)
  }

  gateway_ip_configuration {
    name      = try("${local.prefix}-IpConfGW", null)
    subnet_id = data.azurerm_subnet.frontend.id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = data.azurerm_public_ip.appgateway.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  dynamic "frontend_port" {
    for_each = local.frontend_ports

    content {
      name = try(frontend_port.value.name, local.prefix)
      port = try(frontend_port.value.port, null)
    }
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = "80"
    protocol              = "Http"
    request_timeout       = 30
  }

  dynamic "ssl_certificate" {
    for_each = local.key_vault_certificates

    content {
      name                = try(ssl_certificate.value.name, null)
      key_vault_secret_id = try(ssl_certificate.value.secret_id, null)
    }
  }

  dynamic "http_listener" {
    for_each = local.frontend_ports

    content {
      name                           = "${http_listener.key}-listener"
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = try(http_listener.value.name, null)
      protocol                       = try(http_listener.key, null)

      ssl_certificate_name = http_listener.key == "Https" ? data.azurerm_key_vault_certificate.ssl_certificates.name : null
    }
  }

  dynamic "request_routing_rule" {
    for_each = local.frontend_ports

    content {
      name                       = "${request_routing_rule.key}-rule"
      priority                   = try(request_routing_rule.value.port, null)
      rule_type                  = "Basic"
      http_listener_name         = "${request_routing_rule.key}-listener"
      backend_address_pool_name  = local.backend_address_pool_name
      backend_http_settings_name = local.http_setting_name
    }
  }
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "main" {
  network_interface_id    = data.azurerm_network_interface.nic.id
  ip_configuration_name   = "ClaxtonLab-NIC-ip_configuration"
  backend_address_pool_id = tolist(azurerm_application_gateway.network.backend_address_pool).0.id
}
