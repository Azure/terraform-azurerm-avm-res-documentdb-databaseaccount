resource "azurerm_cosmosdb_sql_database" "this" {
  for_each = local.normalized_sql_databases

  name = each.key

  account_name        = azurerm_cosmosdb_account.this.name
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name

  throughput = each.value.throughput

  dynamic "autoscale_settings" {
    for_each = try(each.value.autoscale_settings.max_throughput, null) != null ? [1] : []

    content {
      max_throughput = each.value.autoscale_settings.max_throughput
    }
  }

  lifecycle {
    precondition {
      condition     = try(each.value.autoscale_settings.max_throughput, null) != null && each.value.throughput != null ? false : true
      error_message = "The 'throughput' and 'autoscale_settings.max_throughput' cannot be specified at the same time."
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

      conflict_resolution_path      = each.value.container_params.conflict_resolution_policy.conflict_resolution_path
      conflict_resolution_procedure = each.value.container_params.conflict_resolution_policy.conflict_resolution_procedure
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
}

resource "azurerm_cosmosdb_sql_function" "example" {
  for_each = local.sql_container_functions

  name         = each.value.function_name
  body         = each.value.function_params.body
  container_id = azurerm_cosmosdb_sql_container.this["${each.value.db_name}|${each.value.container_name}"].id
}