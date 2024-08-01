terraform {
  required_version = "~> 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.71"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_client_config" "current" {}

locals {
  prefix = "cmk-pin"
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.3.0"

  recommended_regions_only = true
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

resource "azurerm_resource_group" "example" {
  location = "spaincentral"
  name     = "${module.naming.resource_group.name_unique}-${local.prefix}"
}

resource "azurerm_user_assigned_identity" "example" {
  location            = azurerm_resource_group.example.location
  name                = "example-${local.prefix}"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_key_vault" "example" {
  location                   = azurerm_resource_group.example.location
  name                       = "${module.naming.key_vault.name_unique}${local.prefix}"
  resource_group_name        = azurerm_resource_group.example.name
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization  = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 7
}

resource "azurerm_key_vault_key" "example" {
  key_opts = [
    "wrapKey",
    "unwrapKey"
  ]
  key_type     = "RSA"
  key_vault_id = azurerm_key_vault.example.id
  name         = "customermanagedkey"
  key_size     = 4096

  depends_on = [time_sleep.wait_for_rbac_before_key_operations]
}

resource "azurerm_role_assignment" "crypto_officer" {
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_key_vault.example.id
  role_definition_name = "Key Vault Crypto Officer"
}

resource "azurerm_role_assignment" "crypto_service_encryption_user" {
  principal_id         = azurerm_user_assigned_identity.example.principal_id
  scope                = azurerm_key_vault.example.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
}

resource "time_sleep" "wait_for_rbac_before_key_operations" {
  create_duration = "90s"

  depends_on = [azurerm_role_assignment.crypto_officer, azurerm_role_assignment.crypto_service_encryption_user]
}

module "cosmos" {
  source = "../../"

  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  name                = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"

  managed_identities = {
    user_assigned_resource_ids = [azurerm_user_assigned_identity.example.id]
  }

  customer_managed_key = {
    key_vault_resource_id = azurerm_key_vault.example.id
    key_name              = azurerm_key_vault_key.example.name

    user_assigned_identity = {
      resource_id = azurerm_user_assigned_identity.example.id
    }
  }

  depends_on = [time_sleep.wait_for_rbac_before_key_operations]
}
