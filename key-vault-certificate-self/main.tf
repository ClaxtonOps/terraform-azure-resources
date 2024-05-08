resource "random_string" "main" {
  length  = 10
  special = false
  numeric = false
}

data "azurerm_client_config" "current" {
}

data "azurerm_resource_group" "rg" {
  name = "ClaxtonLab-RG"
}

resource "azurerm_user_assigned_identity" "this" {
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  name                = try(local.keyVault.user_assigned_identity_name, null)
}

resource "azurerm_key_vault" "main" {
  name = try("${local.keyVault.name}-${random_string.main.result}", null)

  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  tenant_id = data.azurerm_client_config.current.tenant_id

  soft_delete_retention_days = 90
  purge_protection_enabled   = false
  sku_name                   = "standard"

  dynamic "access_policy" {
    for_each = local.access_policy

    content {
      tenant_id = try(access_policy.value.tenant_id, null)
      object_id = try(access_policy.value.object_id, null)

      certificate_permissions = try(access_policy.value.certificate_permissions, null)
      key_permissions         = try(access_policy.value.key_permissions, null)
      secret_permissions      = try(access_policy.value.secret_permissions, null)
    }
  }
}

resource "azurerm_key_vault_certificate" "certificate" {
  name         = try(local.certificate.name, null)
  key_vault_id = azurerm_key_vault.main.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = try(local.certificate.key_properties.exportable, null)
      key_size   = try(local.certificate.key_properties.key_size, null)
      key_type   = try(local.certificate.key_properties.key_type, null)
      reuse_key  = try(local.certificate.key_properties.reuse_key, null)
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = try(local.certificate.content_type, null)
    }

    x509_certificate_properties {
      extended_key_usage = try(local.certificate.extended_key_usage, null)

      key_usage = try(local.certificate.key_usage, null)

      subject_alternative_names {
        dns_names = [local.certificate.dns_name]
      }

      subject            = "CN=${local.certificate.dns_name}"
      validity_in_months = 12
    }
  }
}