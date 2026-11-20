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
  prefix = "mongo"
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

  location                   = azapi_resource.resource_group.location
  name                       = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"
  parent_id                  = azapi_resource.resource_group.id
  analytical_storage_enabled = true
  enable_telemetry           = var.enable_telemetry
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
  mongo_server_version = "3.6"
}
