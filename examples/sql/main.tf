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
  prefix = "sql"
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

  location         = azapi_resource.resource_group.location
  name             = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"
  parent_id        = azapi_resource.resource_group.id
  enable_telemetry = var.enable_telemetry
  geo_locations = [
    {
      failover_priority = 0
      zone_redundant    = false
      location          = azapi_resource.resource_group.location
    }
  ]
  sql_databases = {
    empty_database = {
      name = "empty_database"

      containers = {
        empty_container = {
          name                = "empty_container"
          partition_key_paths = ["/id"]
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
          name                = "container_fixed_througput"
          partition_key_paths = ["/id"]
          throughput          = 400
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
          name                = "container_fixed_througput"
          partition_key_paths = ["/id"]

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
          name                = "container_fixed_througput"
          partition_key_paths = ["/id"]
          throughput          = 400
        }

        container_autoscale_througput = {
          name                = "container_autoscale_througput"
          partition_key_paths = ["/id"]

          autoscale_settings = {
            max_throughput = 4000
          }
        }

        container_document_ttl = {
          name                = "container_document_ttl"
          partition_key_paths = ["/id"]
          default_ttl         = 1000
        }

        container_unique_keys = {
          name                = "container_unique_keys"
          partition_key_paths = ["/id"]

          unique_keys = [
            {
              paths = ["/field1", "/field2"]
            }
          ]
        }

        container_conflict_resolution_with_path = {
          name                = "container_conflict_resolution_with_path"
          partition_key_paths = ["/id"]

          conflict_resolution_policy = {
            mode                     = "LastWriterWins"
            conflict_resolution_path = "/customProperty"
          }
        }

        container_conflict_resolution_with_stored_procedure = {
          name                = "container_conflict_resolution_with_stored_procedure"
          partition_key_paths = ["/id"]

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
          name                = "container_with_functions"
          partition_key_paths = ["/id"]

          functions = {
            empty = {
              name = "empty"
              body = "function empty() { return; }"
            }
          }
        }

        container_with_stored_procedures = {
          name                = "container_with_stored_procedures"
          partition_key_paths = ["/id"]

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
          name                = "container_with_triggers"
          partition_key_paths = ["/id"]

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
          name                = "container_with_none_index_policy"
          partition_key_paths = ["/id"]

          indexing_policy = {
            indexing_mode = "none"
          }
        }

        container_with_consistent_index_policy = {
          name                = "container_with_consistent_index_policy"
          partition_key_paths = ["/id"]

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
