provider "azurerm" {
  features {}
}


locals {
  keyVault = {
    name = "Vault-claxtonops"

    user_assigned_identity_name = "Identity-KV-AppGw"

  }

  access_policy = {

    user_policy = {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = data.azurerm_client_config.current.object_id

      key_permissions         = ["Create", "Get", "Delete", "List", "Update", "Import", "Backup", "Restore", "Recover"]
      secret_permissions      = ["Set", "Get", "Delete", "List", "Recover", "Backup", "Restore"]
      certificate_permissions = ["Create", "Delete", "Get", "List", "Update", "ManageContacts", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"]
    },

    identity_policy = {
      tenant_id = azurerm_user_assigned_identity.this.tenant_id
      object_id = azurerm_user_assigned_identity.this.principal_id

      key_permissions         = ["Get", "List", "Delete"]
      secret_permissions      = ["Get", "List", "Delete"]
      certificate_permissions = ["Get", "List", "Delete"]
    }
  }

  certificate = {
    dns_name = "claxtonopslab.cloud"
    name     = "claxtonopslab"

    key_properties = {
      exportable = true
      key_size   = 4096
      key_type   = "RSA"
      reuse_key  = true
    }

    extended_key_usage = ["1.3.6.1.5.5.7.3.1", "1.3.6.1.5.5.7.3.2"]
    key_usage          = ["cRLSign", "dataEncipherment", "digitalSignature", "keyAgreement", "keyCertSign", "keyEncipherment"]
    content_type       = "application/x-pkcs12"
  }
}