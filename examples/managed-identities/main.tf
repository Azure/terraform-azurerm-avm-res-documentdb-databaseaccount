terraform {
  required_version = ">= 1.16, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
  }
}

locals {
  prefix = "mi"
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

module "cosmos" {
  source = "../../"

  location         = azapi_resource.resource_group.location
  name             = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"
  parent_id        = azapi_resource.resource_group.id
  enable_telemetry = var.enable_telemetry
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azapi_resource.user_assigned_identity.id]
  }
  role_assignments = {
    user_assigned_identity_reader = {
      role_definition_id_or_name = "Cosmos DB Account Reader Role"
      principal_id               = azapi_resource.user_assigned_identity.output.properties.principalId
      principal_type             = "ServicePrincipal"
      description                = "Grants the user assigned identity read access to the account"
    }
  }
}
