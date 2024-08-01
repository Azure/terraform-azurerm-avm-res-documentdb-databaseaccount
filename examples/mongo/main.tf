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

    database_collection = {
      name       = "database_mongoDb_collections"
      throughput = 400

      collections = {
        "collection" = {
          name                = "MongoDBcollection"
          default_ttl_seconds = "3600"
          shard_key           = "_id"
          throughput          = 400

          index = {
            keys   = ["_id"]
            unique = true
          }
        }

        "collection_autoscale" = {
          name = "collection_autoscale_settings"

          default_ttl_seconds = "3600"
          shard_key           = "uniqueKey"

          autoscale_settings = {
            max_throughput = 4000
          }

          index = {
            keys   = ["_id"]
            unique = false
          }
        }
      }
    }

    database_collections_index_keys_unique_false = {
      name       = "database_collections_index_keys_unique_false"
      throughput = 400

      collections = {
        "collection" = {
          name                = "collections_index_keys_unique_false"
          default_ttl_seconds = "3600"
          shard_key           = "uniqueKey"
          throughput          = 400

          index = {
            keys   = ["_id"]
            unique = false
          }
        }
      }
    }
  }
}

