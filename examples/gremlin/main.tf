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

locals {
  prefix = "gremlin"
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
  location = "spaincentral"
  name     = "${module.naming.resource_group.name_unique}-${local.prefix}"
}

module "cosmos" {
  source = "../../"

  location                   = azurerm_resource_group.example.location
  name                       = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"
  resource_group_name        = azurerm_resource_group.example.name
  analytical_storage_enabled = true
  capabilities = [{
    name = "EnableGremlin"
  }]
  gremlin_databases = {
    empty_database = {
      name       = "empty_database"
      throughput = 400
    }

    database_autoscale_throughput = {
      name = "database_autoscale_throughput"

      autoscale_settings = {
        max_throughput = 4000
      }
    }

    database_with_fixed_throughput = {
      name       = "database_with_fixed_throughput"
      throughput = 400
    }

    database_with_graphs = {
      name       = "database_with_graphs"
      throughput = 400

      graphs = {
        "graph_fixed_throughput" = {
          name               = "graph_fixed_throughput"
          partition_key_path = "/partitionKey"
          throughput         = 400
        }

        "graph_autoscale" = {
          name               = "graph_autoscale"
          partition_key_path = "/partitionKey"

          autoscale_settings = {
            max_throughput = 4000
          }
        }

        "graph_with_ttl" = {
          name               = "graph_with_ttl"
          partition_key_path = "/partitionKey"
          default_ttl        = 3600
        }

        "graph_with_analytical_storage" = {
          name                   = "graph_with_analytical_storage"
          partition_key_path     = "/partitionKey"
          analytical_storage_ttl = -1
        }

        "graph_with_partition_key_v2" = {
          name                  = "graph_with_partition_key_v2"
          partition_key_path    = "/largePartitionKey"
          partition_key_version = "2"
        }

        "graph_with_index_policy" = {
          name               = "graph_with_index_policy"
          partition_key_path = "/partitionKey"

          index_policy = {
            automatic      = true
            indexing_mode  = "consistent"
            included_paths = ["/", "/included/*"]
            excluded_paths = ["/excluded/*"]

            composite_index = [
              {
                index = [
                  {
                    path  = "/name"
                    order = "Ascending"
                  },
                  {
                    path  = "/age"
                    order = "Descending"
                  }
                ]
              }
            ]

            spatial_index = [
              {
                path = "/location/*"
              }
            ]
          }
        }

        "graph_with_conflict_resolution" = {
          name               = "graph_with_conflict_resolution"
          partition_key_path = "/partitionKey"

          conflict_resolution_policy = {
            mode                     = "LastWriterWins"
            conflict_resolution_path = "/_ts"
          }
        }

        "graph_with_unique_key" = {
          name               = "graph_with_unique_key"
          partition_key_path = "/partitionKey"

          unique_key = {
            paths = ["/uniqueField"]
          }
        }
      }
    }
  }
}
