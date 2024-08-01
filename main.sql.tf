resource "azurerm_cosmosdb_sql_database" "this" {
  for_each = var.sql_databases

  account_name        = azurerm_cosmosdb_account.this.name
  name                = each.value.name
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
  throughput          = each.value.throughput

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

  account_name           = azurerm_cosmosdb_account.this.name
  database_name          = azurerm_cosmosdb_sql_database.this[each.value.db_name].name
  name                   = each.value.container_name
  resource_group_name    = azurerm_cosmosdb_account.this.resource_group_name
  analytical_storage_ttl = each.value.container_params.analytical_storage_ttl
  default_ttl            = each.value.container_params.default_ttl
  partition_key_path     = each.value.container_params.partition_key_path
  partition_key_version  = 2
  throughput             = each.value.container_params.throughput

  dynamic "autoscale_settings" {
    for_each = try(each.value.container_params.autoscale_settings.max_throughput, null) != null ? [1] : []

    content {
      max_throughput = each.value.container_params.autoscale_settings.max_throughput
    }
  }
  dynamic "conflict_resolution_policy" {
    for_each = each.value.container_params.conflict_resolution_policy != null ? [1] : []

    content {
      mode                          = each.value.container_params.conflict_resolution_policy.mode
      conflict_resolution_path      = each.value.container_params.conflict_resolution_policy.mode == "LastWriterWins" ? each.value.container_params.conflict_resolution_policy.conflict_resolution_path : null
      conflict_resolution_procedure = each.value.container_params.conflict_resolution_policy.mode == "Custom" ? "dbs/{${each.value.db_name}}/colls/{${each.value.container_name}}/sprocs/{${each.value.container_params.conflict_resolution_policy.conflict_resolution_procedure}}" : null
    }
  }
  dynamic "indexing_policy" {
    for_each = each.value.container_params.indexing_policy != null ? [1] : []

    content {
      indexing_mode = each.value.container_params.indexing_policy.indexing_mode

      dynamic "composite_index" {
        for_each = each.value.container_params.indexing_policy.composite_indexes

        content {
          dynamic "index" {
            for_each = composite_index.value.indexes

            content {
              order = index.value.order
              path  = index.value.path
            }
          }
        }
      }
      dynamic "excluded_path" {
        for_each = each.value.container_params.indexing_policy.excluded_paths

        content {
          path = excluded_path.value.path
        }
      }
      dynamic "included_path" {
        for_each = each.value.container_params.indexing_policy.included_paths

        content {
          path = included_path.value.path
        }
      }
      dynamic "spatial_index" {
        for_each = each.value.container_params.indexing_policy.spatial_indexes

        content {
          path = spatial_index.value.path
        }
      }
    }
  }
  dynamic "unique_key" {
    for_each = each.value.container_params.unique_keys

    content {
      paths = unique_key.value.paths
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

  body         = each.value.function_params.body
  container_id = azurerm_cosmosdb_sql_container.this[each.value.container_key].id
  name         = each.value.function_name
}

resource "azurerm_cosmosdb_sql_stored_procedure" "this" {
  for_each = local.sql_container_stored_procedures

  account_name        = azurerm_cosmosdb_account.this.name
  body                = each.value.stored_params.body
  container_name      = azurerm_cosmosdb_sql_container.this[each.value.container_key].name
  database_name       = azurerm_cosmosdb_sql_database.this[each.value.db_name].name
  name                = each.value.stored_name
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
}

resource "azurerm_cosmosdb_sql_trigger" "this" {
  for_each = local.sql_container_triggers

  body         = each.value.trigger_params.body
  container_id = azurerm_cosmosdb_sql_container.this[each.value.container_key].id
  name         = each.value.trigger_name
  operation    = each.value.trigger_params.operation
  type         = each.value.trigger_params.type
}

resource "azurerm_cosmosdb_sql_dedicated_gateway" "this" {
  count = var.sql_dedicated_gateway != null && length(var.sql_databases) > 0 ? 1 : 0

  cosmosdb_account_id = azurerm_cosmosdb_account.this.id
  instance_count      = var.sql_dedicated_gateway.instance_count
  instance_size       = var.sql_dedicated_gateway.instance_size
}
