terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
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
  prefix = "max"
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = "0.3.0"

  recommended_regions_only = true
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

resource "azurerm_resource_group" "example" {
  location = "northeurope"
  name     = "${module.naming.resource_group.name_unique}-${local.prefix}"
}

resource "azurerm_log_analytics_workspace" "example" {
  location            = azurerm_resource_group.example.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.example.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

module "cosmos" {
  source = "../../"

  location                           = azurerm_resource_group.example.location
  name                               = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"
  resource_group_name                = azurerm_resource_group.example.name
  access_key_metadata_writes_enabled = true
  analytical_storage_config = {
    schema_type = "WellDefined"
  }
  analytical_storage_enabled = true
  automatic_failover_enabled = false
  backup = {
    retention_in_hours  = 8
    interval_in_minutes = 1440
    storage_redundancy  = "Geo"
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
      workspace_resource_id = azurerm_log_analytics_workspace.example.id
      metric_categories = ["SLI", "Requests"]
    }
  }
  enable_telemetry = false
  geo_locations = [
    {
      failover_priority = 0
      zone_redundant    = false
      location          = azurerm_resource_group.example.location
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
      principal_id                     = data.azurerm_client_config.current.object_id
    }
  }
  tags = {
    environment = "testing"
    department  = "engineering"
  }
}
