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
  location = "northeurope"
  name     = "${module.naming.resource_group.name_unique}-${local.prefix}"
}

module "cosmos" {
  source = "../../"

  resource_group_name        = azurerm_resource_group.example.name
  location                   = azurerm_resource_group.example.location
  name                       = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"
  analytical_storage_enabled = true

  geo_locations = [ #Sql Gateway in a region with zone redundant enabled require a support ticket to allow it
    {
      failover_priority = 0
      zone_redundant    = false
      location          = azurerm_resource_group.example.location
    }
  ]

  sql_dedicated_gateway = {
    instance_count = 1
    instance_size  = "Cosmos.D4s"
  }

  sql_databases = {
    empty_database = {
      name = "empty_database"

      containers = {
        empty_container = {
          name               = "empty_container"
          partition_key_path = "/id"
        }
      }
    }

    database_fixed_througput = {
      name       = "database_fixed_througput"
      throughput = 400
    }

    database_autoscale_througput = {
      name = "database_autoscale_througput"

      autoscale_settings = {
        max_throughput = 4000
      }
    }

    database_and_container_fixed_througput = {
      name       = "database_and_container_fixed_througput"
      throughput = 400

      containers = {
        container_fixed_througput = {
          name               = "container_fixed_througput"
          partition_key_path = "/id"
          throughput         = 400
        }
      }
    }

    database_and_container_autoscale_througput = {
      name = "database_and_container_autoscale_througput"

      autoscale_settings = {
        max_throughput = 4000
      }

      containers = {
        container_fixed_througput = {
          name               = "container_fixed_througput"
          partition_key_path = "/id"

          autoscale_settings = {
            max_throughput = 4000
          }
        }
      }
    }

    database_containers_tests = {
      name = "database_containers_tests"

      containers = {
        container_fixed_througput = {
          name               = "container_fixed_througput"
          partition_key_path = "/id"
          throughput         = 400
        }

        container_autoscale_througput = {
          name               = "container_autoscale_througput"
          partition_key_path = "/id"

          autoscale_settings = {
            max_throughput = 4000
          }
        }

        container_infinite_analytical_ttl = {
          name                   = "container_infinite_analytical_ttl"
          partition_key_path     = "/id"
          analytical_storage_ttl = -1
        }

        container_fixed_analytical_ttl = {
          name                   = "container_fixed_analytical_ttl"
          partition_key_path     = "/id"
          analytical_storage_ttl = 1000
        }

        container_document_ttl = {
          name               = "container_document_ttl"
          partition_key_path = "/id"
          default_ttl        = 1000
        }

        container_unique_keys = {
          name               = "container_unique_keys"
          partition_key_path = "/id"

          unique_keys = [
            {
              paths = ["/field1", "/field2"]
            }
          ]
        }

        container_conflict_resolution_with_path = {
          name               = "container_conflict_resolution_with_path"
          partition_key_path = "/id"

          conflict_resolution_policy = {
            mode                     = "LastWriterWins"
            conflict_resolution_path = "/customProperty"
          }
        }

        container_conflict_resolution_with_stored_procedure = {
          name               = "container_conflict_resolution_with_stored_procedure"
          partition_key_path = "/id"

          conflict_resolution_policy = {
            mode                          = "Custom"
            conflict_resolution_procedure = "resolver"
          }

          stored_procedures = {
            resolver = {
              name = "resolver"
              body = "function resolver(incomingItem, existingItem, isTombstone, conflictingItems) { }"
            }
          }
        }

        container_with_functions = {
          name               = "container_with_functions"
          partition_key_path = "/id"

          functions = {
            empty = {
              name = "empty"
              body = "function empty() { return; }"
            }
          }
        }

        container_with_stored_procedures = {
          name               = "container_with_stored_procedures"
          partition_key_path = "/id"

          stored_procedures = {
            empty = {
              name = "empty"
              body = <<BODY
                function empty() { }
              BODY
            }
          }
        }

        container_with_triggers = {
          name               = "container_with_triggers"
          partition_key_path = "/id"

          triggers = {
            testTrigger = {
              name      = "testTrigger"
              body      = "function testTrigger(){}"
              operation = "Delete"
              type      = "Post"
            }
          }
        }

        container_with_none_index_policy = {
          name               = "container_with_none_index_policy"
          partition_key_path = "/id"

          indexing_policy = {
            indexing_mode = "none"
          }
        }

        container_with_consistent_index_policy = {
          name               = "container_with_consistent_index_policy"
          partition_key_path = "/id"

          indexing_policy = {
            indexing_mode = "consistent"

            included_paths = [
              {
                path = "/hola/?"
              }
            ]
            excluded_paths = [
              {
                path = "/*"
              }
            ]
            spatial_indexes = [
              {
                path = "/field2/?"
              }
            ]
            composite_indexes = [
              {
                indexes = [
                  {
                    path  = "/field3"
                    order = "Ascending"
                  },
                  {
                    path  = "/field4"
                    order = "Descending"
                  }
                ]
              }
            ]
          }
        }
      }
    }
  }
}

output "name" {
  value = module.cosmos.sql_databases
}