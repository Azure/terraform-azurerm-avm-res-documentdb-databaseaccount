terraform {
  required_version = ">= 1.9, < 2.0"

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
  prefix = "mongo"
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

module "cosmos" {
  source = "../../"

  resource_group_name        = azurerm_resource_group.example.name
  location                   = azurerm_resource_group.example.location
  name                       = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"
  mongo_server_version       = "3.6"
  analytical_storage_enabled = true

  mongo_databases = {
    empty_database = {
      name       = "empty_database"
      throughput = 400
    }

    database_autoscale_througput = {
      name = "database_autoscale_througput"

      autoscale_settings = {
        max_throughput = 4000
      }
    }

    database_with_fixed_throughput = {
      name       = "database_with_fixed_throughput"
      throughput = 400
    }

    database_with_collections = {
      name       = "database_with_collections"
      throughput = 400

      collections = {
        "collection_fixed_throughput" = {
          name       = "collection_fixed_throughput"
          throughput = 400
        }

        "collection_autoscale" = {
          name = "collection_autoscale"

          autoscale_settings = {
            max_throughput = 4000
          }
        }

        "collections_with_ttl" = {
          name                = "collections_with_ttl"
          default_ttl_seconds = 3600
        }

        "collections_custom_shard_key" = {
          name      = "collections_custom_shard_key"
          shard_key = "_id"
        }

        "collections_index_keys_unique_false" = {
          name = "collections_index_keys_unique_false"

          index = {
            keys   = ["testproperty"]
            unique = false
          }
        }

        "collections_index_keys_unique_true" = {
          name = "collections_index_keys_unique_true"

          index = {
            keys   = ["testproperty"]
            unique = true
          }
        }
      }
    }
  }
}
