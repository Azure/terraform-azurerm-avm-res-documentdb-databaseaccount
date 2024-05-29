resource "azurerm_cosmosdb_sql_database" "this" {
  for_each = var.sql_databases

  name       = each.value.name
  throughput = each.value.throughput

  account_name        = azurerm_cosmosdb_account.this.name
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name

  dynamic "autoscale_settings" {
    for_each = try(each.value.autoscale_settings.max_throughput, null) != null ? [1] : []

    content {
      max_throughput = each.value.autoscale_settings.max_throughput
    }
  }

  lifecycle {
    precondition {
      condition     = contains(var.capabilities[*].name, local.serverless_capability) && (each.value.throughput != null || try(each.value.autoscale_settings.max_throughput, null) != null) ? false : true
      error_message = "Serverless containers must not specify 'throughput' or 'autoscale_settings.max_throughput' at the database level."
    }
  }
}

resource "azurerm_cosmosdb_sql_container" "this" {
  for_each = local.sql_containers

  name = each.value.container_name

  account_name        = azurerm_cosmosdb_account.this.name
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
  database_name       = azurerm_cosmosdb_sql_database.this[each.value.db_name].name

  partition_key_version  = 2
  throughput             = each.value.container_params.throughput
  default_ttl            = each.value.container_params.default_ttl
  partition_key_path     = each.value.container_params.partition_key_path
  analytical_storage_ttl = each.value.container_params.analytical_storage_ttl

  dynamic "unique_key" {
    for_each = each.value.container_params.unique_keys

    content {
      paths = unique_key.value.paths
    }
  }

  dynamic "autoscale_settings" {
    for_each = try(each.value.container_params.autoscale_settings.max_throughput, null) != null ? [1] : []

    content {
      max_throughput = each.value.container_params.autoscale_settings.max_throughput
    }
  }

  dynamic "conflict_resolution_policy" {
    for_each = each.value.container_params.conflict_resolution_policy != null ? [1] : []

    content {
      mode = each.value.container_params.conflict_resolution_policy.mode

      conflict_resolution_path      = each.value.container_params.conflict_resolution_policy.mode == "LastWriterWins" ? each.value.container_params.conflict_resolution_policy.conflict_resolution_path : null
      conflict_resolution_procedure = each.value.container_params.conflict_resolution_policy.mode == "Custom" ? "dbs/{${each.value.db_name}}/colls/{${each.value.container_name}}/sprocs/{${each.value.container_params.conflict_resolution_policy.conflict_resolution_procedure}}" : null
    }
  }

  dynamic "indexing_policy" {
    for_each = each.value.container_params.indexing_policy != null ? [1] : []

    content {
      indexing_mode = each.value.container_params.indexing_policy.indexing_mode

      dynamic "included_path" {
        for_each = each.value.container_params.indexing_policy.included_paths

        content {
          path = included_path.value.path
        }
      }

      dynamic "excluded_path" {
        for_each = each.value.container_params.indexing_policy.excluded_paths

        content {
          path = excluded_path.value.path
        }
      }

      dynamic "spatial_index" {
        for_each = each.value.container_params.indexing_policy.spatial_indexes

        content {
          path = spatial_index.value.path
        }
      }

      dynamic "composite_index" {
        for_each = each.value.container_params.indexing_policy.composite_indexes

        content {
          dynamic "index" {
            for_each = composite_index.value.indexes

            content {
              path  = index.value.path
              order = index.value.order
            }
          }
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = contains(var.capabilities[*].name, local.serverless_capability) && (each.value.container_params.throughput != null || try(each.value.container_params.autoscale_settings.max_throughput, null) != null) ? false : true
      error_message = "Serverless containers must not specify 'throughput' or 'autoscale_settings.max_throughput' at the container level."
    }
  }
}

resource "azurerm_cosmosdb_sql_function" "this" {
  for_each = local.sql_container_functions

  name         = each.value.function_name
  body         = each.value.function_params.body
  container_id = azurerm_cosmosdb_sql_container.this[each.value.container_key].id
}

resource "azurerm_cosmosdb_sql_stored_procedure" "this" {
  for_each = local.sql_container_stored_procedures

  name = each.value.stored_name

  body = each.value.stored_params.body

  account_name        = azurerm_cosmosdb_account.this.name
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
  database_name       = azurerm_cosmosdb_sql_database.this[each.value.db_name].name
  container_name      = azurerm_cosmosdb_sql_container.this[each.value.container_key].name
}

resource "azurerm_cosmosdb_sql_trigger" "this" {
  for_each = local.sql_container_triggers

  name = each.value.trigger_name

  body      = each.value.trigger_params.body
  type      = each.value.trigger_params.type
  operation = each.value.trigger_params.operation

  container_id = azurerm_cosmosdb_sql_container.this[each.value.container_key].id
}

resource "azurerm_cosmosdb_sql_dedicated_gateway" "this" {
  count = var.sql_dedicated_gateway != null && length(var.sql_databases) > 0 ? 1 : 0

  instance_count = var.sql_dedicated_gateway.instance_count
  instance_size  = var.sql_dedicated_gateway.instance_size

  cosmosdb_account_id = azurerm_cosmosdb_account.this.id
}
