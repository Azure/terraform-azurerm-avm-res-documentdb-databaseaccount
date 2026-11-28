terraform {
  required_version = ">= 1.16, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
  }
}

data "azapi_client_config" "current" {}

locals {
  prefix = "max"
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

resource "azapi_resource" "log_analytics_workspace" {
  location  = azapi_resource.resource_group.location
  name      = module.naming.log_analytics_workspace.name_unique
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.OperationalInsights/workspaces@2023-09-01"
  body = {
    properties = {
      retentionInDays = 30
      sku = {
        name = "PerGB2018"
      }
    }
  }
}

module "cosmos" {
  source = "../../"

  location                           = azapi_resource.resource_group.location
  name                               = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"
  parent_id                          = azapi_resource.resource_group.id
  access_key_metadata_writes_enabled = true
  analytical_storage_config = {
    schema_type = "WellDefined"
  }
  automatic_failover_enabled = false
  backup = {
    retention_in_hours  = 8
    interval_in_minutes = 1440
    storage_redundancy  = "Zone"
    type                = "Periodic"
  }
  capacity = {
    total_throughput_limit = 10000
  }
  consistency_policy = {
    consistency_level = "Session"
  }
  cors_rule = {
    max_age_in_seconds = 3600
    allowed_origins    = ["*"]
    exposed_headers    = ["*"]
    allowed_headers    = ["Authorization"]
    allowed_methods    = ["GET", "POST", "PUT"]
  }
  diagnostic_settings = {
    cosmosdb = {
      name                  = "diag"
      workspace_resource_id = azapi_resource.log_analytics_workspace.id
      metric_categories     = ["SLI", "Requests"]
    }
  }
  enable_telemetry = var.enable_telemetry
  geo_locations = [
    {
      failover_priority = 0
      zone_redundant    = false
      location          = azapi_resource.resource_group.location
    }
  ]
  local_authentication_disabled = false
  lock = {
    kind = "CanNotDelete"
    name = "Testing name CanNotDelete"
  }
  multiple_write_locations_enabled = true
  partition_merge_enabled          = false
  public_network_access_enabled    = false
  role_assignments = {
    key = {
      skip_service_principal_aad_check = false
      role_definition_id_or_name       = "Contributor"
      description                      = "This is a test role assignment"
      principal_id                     = data.azapi_client_config.current.object_id
    }
  }
  tags = {
    environment = "testing"
    department  = "engineering"
  }
}
