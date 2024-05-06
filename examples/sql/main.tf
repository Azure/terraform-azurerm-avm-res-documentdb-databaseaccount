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
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

locals {
  prefix = "sql"
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
  name     = "${module.naming.resource_group.name_unique}-${local.prefix}"
  location = "northeurope"
}

module "cosmos" {
  source = "../../"

  resource_group_name        = azurerm_resource_group.example.name
  location                   = azurerm_resource_group.example.location
  name                       = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"
  analytical_storage_enabled = true

  geo_locations = [
    {
      failover_priority = 0
      location          = azurerm_resource_group.example.location
    }
  ]

  sql_databases = {
    database_fixed_througput = {
      throughput = 400
    }

    database_autoscale_througput = {
      autoscale_settings = {
        max_throughput = 4000
      }
    }

    database_and_container_fixed_througput = {
      throughput = 400
      container_fixed_througput = {
        partition_key_path = "/id"
        throughput         = 400
      }
    }

    database_and_container_autoscale_througput = {
      autoscale_settings = {
        max_throughput = 4000
      }
      container_fixed_througput = {
        partition_key_path = "/id"
        autoscale_settings = {
          max_throughput = 4000
        }
      }
    }

    database_containers_tests = {
      containers = {
        container_fixed_througput = {
          partition_key_path = "/id"
          throughput         = 400
        }

        container_autoscale_througput = {
          partition_key_path = "/id"
          autoscale_settings = {
            max_throughput = 4000
          }
        }

        container_infinite_analytical_ttl = {
          partition_key_path     = "/id"
          analytical_storage_ttl = -1
        }

        container_fixed_analytical_ttl = {
          partition_key_path     = "/id"
          analytical_storage_ttl = 1000
        }

        container_document_ttl = {
          partition_key_path = "/id"
          default_ttl        = 1000
        }

        container_unique_keys = {
          partition_key_path = "/id"
          unique_keys = [
            {
              paths = ["/field1", "/field2"]
            }
          ]
        }

        container_conflict_resolution_with_path = {
          partition_key_path = "/id"
          conflict_resolution_policy = {
            mode                     = "LastWriterWins"
            conflict_resolution_path = "/customProperty"
          }
        }
      }
    }
  }
}
