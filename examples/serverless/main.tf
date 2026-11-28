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
  prefix = "less"
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

module "cosmos" {
  source = "../../"

  location  = azapi_resource.resource_group.location
  name      = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"
  parent_id = azapi_resource.resource_group.id
  capabilities = [
    {
      name = "EnableServerless"
    }
  ]
  enable_telemetry = var.enable_telemetry
}
