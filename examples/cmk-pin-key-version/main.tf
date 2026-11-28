terraform {
  required_version = ">= 1.16, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

data "azapi_client_config" "current" {}

locals {
  prefix = "cmk-pin"
}

module "naming" {
  source  = "Azure/avm-utl-naming/azure"
  version = "0.2.0"
}

resource "azapi_resource" "resource_group" {
  location = "spaincentral"
  name     = "${module.naming.resource_group.name_unique}-${local.prefix}"
  type     = "Microsoft.Resources/resourceGroups@2024-03-01"
}

resource "azapi_resource" "user_assigned_identity" {
  location               = azapi_resource.resource_group.location
  name                   = "example-${local.prefix}"
  parent_id              = azapi_resource.resource_group.id
  type                   = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  response_export_values = ["properties.principalId"]
}

resource "azapi_resource" "key_vault" {
  location  = azapi_resource.resource_group.location
  name      = "${module.naming.key_vault.name_unique}${local.prefix}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.KeyVault/vaults@2023-07-01"
  body = {
    properties = {
      tenantId = data.azapi_client_config.current.tenant_id
      sku = {
        family = "A"
        name   = "standard"
      }
      enableRbacAuthorization   = true
      enablePurgeProtection     = true
      enableSoftDelete          = true
      softDeleteRetentionInDays = 7
    }
  }
  response_export_values = ["properties.vaultUri"]
}

# The key is managed through the Key Vault data plane because the ARM vaults/keys API cannot delete keys.
resource "azapi_data_plane_resource" "key_vault_key" {
  name      = "customermanagedkey"
  parent_id = trimsuffix(trimprefix(azapi_resource.key_vault.output.properties.vaultUri, "https://"), "/")
  type      = "Microsoft.KeyVault/vaults/keys@7.4"
  body = {
    kty      = "RSA"
    key_size = 4096
    key_ops = [
      "wrapKey",
      "unwrapKey"
    ]
  }

  depends_on = [time_sleep.wait_for_rbac_before_key_operations]
}

resource "random_uuid" "crypto_officer" {}

resource "azapi_resource" "role_assignment_crypto_officer" {
  name      = random_uuid.crypto_officer.result
  parent_id = azapi_resource.key_vault.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = data.azapi_client_config.current.object_id
      roleDefinitionId = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/14b46e9e-c2b7-41b4-b07b-48a6ebf60603"
    }
  }
}

resource "random_uuid" "crypto_service_encryption_user" {}

resource "azapi_resource" "role_assignment_crypto_service_encryption_user" {
  name      = random_uuid.crypto_service_encryption_user.result
  parent_id = azapi_resource.key_vault.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = azapi_resource.user_assigned_identity.output.properties.principalId
      principalType    = "ServicePrincipal"
      roleDefinitionId = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/e147488a-f6f5-4113-8e2d-b22465e65bf6"
    }
  }
}

resource "time_sleep" "wait_for_rbac_before_key_operations" {
  create_duration = "90s"

  depends_on = [azapi_resource.role_assignment_crypto_officer, azapi_resource.role_assignment_crypto_service_encryption_user]
}

module "cosmos" {
  source = "../../"

  location  = azapi_resource.resource_group.location
  name      = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"
  parent_id = azapi_resource.resource_group.id
  customer_managed_key = {
    key_vault_resource_id = azapi_resource.key_vault.id
    key_name              = azapi_data_plane_resource.key_vault_key.name

    user_assigned_identity = {
      resource_id = azapi_resource.user_assigned_identity.id
    }
  }
  enable_telemetry = var.enable_telemetry
  managed_identities = {
    user_assigned_resource_ids = [azapi_resource.user_assigned_identity.id]
  }

  depends_on = [time_sleep.wait_for_rbac_before_key_operations]
}
