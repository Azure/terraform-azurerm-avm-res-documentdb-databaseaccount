mock_provider "azapi" {
  alias = "mocked"

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-unit-test"
      output = {
        document_endpoint = "https://cosmos-unit-test.documents.azure.com:443/"
        read_endpoints    = []
        write_endpoints   = []
      }
    }
  }

  mock_data "azapi_resource" {
    defaults = {
      exists = false
      output = {
        document_endpoint = "https://cosmos-unit-test.documents.azure.com:443/"
        location          = "North Europe"
      }
    }
  }

  mock_data "azapi_resource_action" {
    defaults = {
      output = {
        locations = [{ name = "northeurope", display_name = "North Europe" }]
      }
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

# Throughput settings are validated against the type of their parent, so each parent needs an ID of its own type.
override_resource {
  target = azapi_resource.sql_databases
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-unit-test/sqlDatabases/db"
  }
}

override_resource {
  target = azapi_resource.sql_containers
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-unit-test/sqlDatabases/db/containers/orders"
  }
}

override_resource {
  target = azapi_resource.mongo_databases
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-unit-test/mongodbDatabases/db"
  }
}

override_resource {
  target = azapi_resource.mongo_collections
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-unit-test/mongodbDatabases/db/collections/orders"
  }
}

override_resource {
  target = azapi_resource.gremlin_databases
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-unit-test/gremlinDatabases/db"
  }
}

override_resource {
  target = azapi_resource.gremlin_graphs
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-unit-test/gremlinDatabases/db/graphs/people"
  }
}

mock_provider "random" {
  alias = "mocked"
}

mock_provider "time" {
  alias = "mocked"
}

variables {
  enable_telemetry = false
  location         = "northeurope"
  name             = "cosmos-unit-test"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test"
}

run "sql_resources_match_earlier_versions" {
  command = apply
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  variables {
    sql_databases = {
      db = {
        name       = "db"
        throughput = 400
        containers = {
          orders = {
            name                = "orders"
            partition_key_paths = ["/customerId"]
            default_ttl         = 3600
            autoscale_settings = {
              max_throughput = 4000
            }
            unique_keys = [{ paths = ["/orderId"] }]
            conflict_resolution_policy = {
              mode                          = "Custom"
              conflict_resolution_procedure = "resolver"
            }
            indexing_policy = {
              indexing_mode   = "consistent"
              included_paths  = [{ path = "/*" }]
              excluded_paths  = [{ path = "/excluded/?" }]
              spatial_indexes = [{ path = "/location/*" }]
              composite_indexes = [
                { indexes = [{ path = "/name", order = "Ascending" }] },
              ]
            }
            functions = {
              tax = { name = "tax", body = "function tax(income) { return income * 0.1; }" }
            }
            stored_procedures = {
              hello = { name = "hello", body = "function hello() { getContext().getResponse().setBody('Hello'); }" }
            }
            triggers = {
              validate = { name = "validate", body = "function validate() {}", type = "Pre", operation = "Create" }
            }
          }
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.sql_databases["db"].body.properties == { options = { throughput = 400 }, resource = { id = "db" } }
    error_message = "A database must be created with its throughput, as before."
  }
  assert {
    condition     = azapi_resource.sql_containers["db|orders"].body.properties.options == { autoscaleSettings = { maxThroughput = 4000 } }
    error_message = "A container must be created with its autoscale throughput."
  }
  assert {
    condition     = azapi_update_resource.sql_database_throughput["db"].body.properties.resource == { throughput = 400 } && azapi_update_resource.sql_container_throughput["db|orders"].body.properties.resource == { autoscaleSettings = { maxThroughput = 4000 } }
    error_message = "Throughput changes must be sent to the throughput settings, as before."
  }
  assert {
    condition     = azapi_resource.sql_containers["db|orders"].body.properties.resource.partitionKey == { kind = "Hash", paths = tolist(["/customerId"]), version = 2 } && azapi_resource.sql_containers["db|orders"].body.properties.resource.defaultTtl == 3600 && azapi_resource.sql_containers["db|orders"].body.properties.resource.analyticalStorageTtl == null
    error_message = "The partition key and time to live must be sent as before."
  }
  assert {
    condition     = azapi_resource.sql_containers["db|orders"].body.properties.resource.conflictResolutionPolicy == { conflictResolutionPath = "", conflictResolutionProcedure = "dbs/{db}/colls/{orders}/sprocs/{resolver}", mode = "Custom" }
    error_message = "The conflict resolution procedure must be sent in the form earlier versions used."
  }
  assert {
    condition = azapi_resource.sql_containers["db|orders"].body.properties.resource.indexingPolicy == {
      compositeIndexes = [[{ order = "ascending", path = "/name" }]]
      excludedPaths    = [{ path = "/excluded/?" }, { path = "/\"_etag\"/?" }]
      includedPaths    = [{ path = "/*" }]
      indexingMode     = "consistent"
      spatialIndexes   = [{ path = "/location/*", types = ["LineString", "MultiPolygon", "Point", "Polygon"] }]
    }
    error_message = "The indexing policy must be sent as the AzureRM provider sent it."
  }
  assert {
    condition     = azapi_resource.sql_containers["db|orders"].replace_triggers_external_values.unique_keys == tolist(["/orderId"]) && azapi_resource.sql_containers["db|orders"].replace_triggers_external_values.partition_key_version == 2
    error_message = "The settings that Azure cannot change must trigger a replacement."
  }
  assert {
    condition     = azapi_resource.sql_triggers["db|orders|validate"].body.properties.resource == { body = "function validate() {}", id = "validate", triggerOperation = "Create", triggerType = "Pre" }
    error_message = "Triggers must send their type and operation."
  }
  assert {
    condition     = contains(keys(output.sql_databases.db.containers.orders.functions), "tax") && contains(keys(output.sql_databases.db.containers.orders.stored_procedures), "hello") && contains(keys(output.sql_databases.db.containers.orders.triggers), "validate")
    error_message = "The output must list the functions, stored procedures and triggers of each container."
  }
}

run "serverless_containers_reject_throughput" {
  command = plan
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  variables {
    capabilities = [{ name = "EnableServerless" }]
    sql_databases = {
      db = {
        name = "db"
        containers = {
          orders = {
            name                = "orders"
            partition_key_paths = ["/customerId"]
            throughput          = 400
          }
        }
      }
    }
  }

  expect_failures = [azapi_resource.sql_containers]
}

run "mongo_resources_match_earlier_versions" {
  command = apply
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  variables {
    local_authentication_disabled = true
    mongo_databases = {
      db = {
        name = "db"
        autoscale_settings = {
          max_throughput = 1000
        }
        collections = {
          orders = {
            name                = "orders"
            default_ttl_seconds = "86400"
            shard_key           = "customerId"
            index = {
              keys   = ["orderId"]
              unique = true
            }
          }
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.kind == "MongoDB" && azapi_resource.this.body.properties.apiProperties == { serverVersion = "3.6" } && azapi_resource.this.body.properties.disableLocalAuth == false
    error_message = "A MongoDB account must keep local authentication enabled and send its server version, as before."
  }
  assert {
    condition     = [for capability in azapi_resource.this.body.properties.capabilities : capability.name] == ["EnableMongo"] && length(azapi_resource.this.replace_triggers_external_values.capabilities) == 0
    error_message = "A MongoDB account must send the EnableMongo capability that Azure adds, without it triggering a replacement."
  }
  assert {
    condition     = azapi_resource.mongo_databases["db"].body.properties.options == { autoscaleSettings = { maxThroughput = 1000 } } && azapi_update_resource.mongo_database_throughput["db"].body.properties.resource == { autoscaleSettings = { maxThroughput = 1000 } }
    error_message = "A database must be created with its autoscale throughput, and later changes sent to its throughput settings."
  }
  assert {
    condition = [
      for index in azapi_resource.mongo_collections["db|orders"].body.properties.resource.indexes :
      "${join(",", index.key.keys)}:${index.options.unique == null ? "-" : tostring(index.options.unique)}:${index.options.expireAfterSeconds == null ? "-" : tostring(index.options.expireAfterSeconds)}"
    ] == ["_id:true:-", "orderId:true:-", "_ts:-:86400"]
    error_message = "The collection must have the _id index, its own index and the time-to-live index last, as before."
  }
  assert {
    condition     = azapi_resource.mongo_collections["db|orders"].body.properties.resource.shardKey == { customerId = "Hash" } && azapi_resource.mongo_collections["db|orders"].replace_triggers_external_values == { shard_key = "customerId" }
    error_message = "The shard key must be sent, and changing it must replace the collection."
  }
  assert {
    condition     = output.mongo_databases.db.collections.orders == azapi_resource.mongo_collections["db|orders"].id
    error_message = "The output must list the collections of each database."
  }
}

run "gremlin_resources_match_earlier_versions" {
  command = apply
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  variables {
    capabilities = [{ name = "EnableGremlin" }]
    gremlin_databases = {
      db = {
        name = "db"
        graphs = {
          people = {
            name                  = "people"
            partition_key_path    = "/country"
            partition_key_version = "2"
            throughput            = 400
            index_policy = {
              indexing_mode  = "consistent"
              included_paths = ["/", "/included/*"]
              excluded_paths = ["/excluded/*"]
            }
            unique_key = {
              paths = ["/email"]
            }
          }
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.this.replace_triggers_external_values.capabilities == tolist(["enablegremlin"])
    error_message = "Adding or removing the Gremlin capability must replace the account, as before."
  }
  assert {
    condition = (
      azapi_resource.gremlin_graphs["db|people"].body.properties.resource.indexingPolicy.automatic &&
      length(azapi_resource.gremlin_graphs["db|people"].body.properties.resource.indexingPolicy.compositeIndexes) == 0 &&
      azapi_resource.gremlin_graphs["db|people"].body.properties.resource.indexingPolicy.excludedPaths == [{ path = "/excluded/*" }, { path = "/\"_etag\"/?" }] &&
      azapi_resource.gremlin_graphs["db|people"].body.properties.resource.indexingPolicy.includedPaths == [{ path = "/" }, { path = "/included/*" }] &&
      azapi_resource.gremlin_graphs["db|people"].body.properties.resource.indexingPolicy.indexingMode == "consistent" &&
      azapi_resource.gremlin_graphs["db|people"].body.properties.resource.indexingPolicy.spatialIndexes == null
    )
    error_message = "The graph indexing policy must be sent as the AzureRM provider sent it."
  }
  assert {
    condition     = azapi_resource.gremlin_graphs["db|people"].body.properties.resource.partitionKey == { kind = "Hash", paths = ["/country"], version = 2 } && azapi_resource.gremlin_graphs["db|people"].body.properties.resource.uniqueKeyPolicy == { uniqueKeys = [{ paths = tolist(["/email"]) }] }
    error_message = "The partition key and unique key must be sent as before."
  }
  assert {
    condition     = azapi_resource.gremlin_graphs["db|people"].body.properties.options == { throughput = 400 } && azapi_update_resource.gremlin_graph_throughput["db|people"].body.properties.resource == { throughput = 400 }
    error_message = "A graph must be created with its throughput, and later changes sent to its throughput settings."
  }
}
