resource "azurerm_cosmosdb_gremlin_database" "this" {
  for_each = var.gremlin_databases

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
}

resource "azurerm_cosmosdb_gremlin_graph" "this" {
  for_each = local.gremlin_graphs

  account_name           = azurerm_cosmosdb_account.this.name
  database_name          = azurerm_cosmosdb_gremlin_database.this[each.value.db_name].name
  name                   = each.value.graph_params.name
  partition_key_path     = each.value.graph_params.partition_key_path
  resource_group_name    = azurerm_cosmosdb_account.this.resource_group_name
  analytical_storage_ttl = each.value.graph_params.analytical_storage_ttl
  default_ttl            = each.value.graph_params.default_ttl
  partition_key_version  = each.value.graph_params.partition_key_version
  throughput             = each.value.graph_params.throughput

  dynamic "autoscale_settings" {
    for_each = try(each.value.graph_params.autoscale_settings.max_throughput, null) != null ? [1] : []

    content {
      max_throughput = each.value.graph_params.autoscale_settings.max_throughput
    }
  }
  dynamic "conflict_resolution_policy" {
    for_each = each.value.graph_params.conflict_resolution_policy != null ? [1] : []

    content {
      mode                          = each.value.graph_params.conflict_resolution_policy.mode
      conflict_resolution_path      = try(each.value.graph_params.conflict_resolution_policy.conflict_resolution_path, null)
      conflict_resolution_procedure = try(each.value.graph_params.conflict_resolution_policy.conflict_resolution_procedure, null)
    }
  }
  dynamic "index_policy" {
    for_each = each.value.graph_params.index_policy != null ? [1] : []

    content {
      indexing_mode  = each.value.graph_params.index_policy.indexing_mode
      automatic      = try(each.value.graph_params.index_policy.automatic, true)
      excluded_paths = try(each.value.graph_params.index_policy.excluded_paths, [])
      included_paths = try(each.value.graph_params.index_policy.included_paths, [])

      dynamic "composite_index" {
        for_each = try(each.value.graph_params.index_policy.composite_index, [])

        content {
          dynamic "index" {
            for_each = composite_index.value.index

            content {
              order = index.value.order
              path  = index.value.path
            }
          }
        }
      }
      dynamic "spatial_index" {
        for_each = try(each.value.graph_params.index_policy.spatial_index, [])

        content {
          path = spatial_index.value.path
        }
      }
    }
  }
  dynamic "unique_key" {
    for_each = each.value.graph_params.unique_key != null ? [1] : []

    content {
      paths = each.value.graph_params.unique_key.paths
    }
  }
}
