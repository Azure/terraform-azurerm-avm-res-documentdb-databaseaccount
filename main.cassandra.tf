resource "azapi_resource" "cassandra_keyspaces" {
  for_each = var.cassandra_keyspaces

  type      = var.resource_types.documentdb_database_accounts_cassandra_keyspaces
  name      = each.value.name
  parent_id = azurerm_cosmosdb_account.this.id

  body = {
    properties = merge(
      {
        resource = {
          id = each.value.name
        }
      },
      each.value.throughput != null || each.value.autoscale_settings != null ? {
        options = merge(
          each.value.throughput != null ? { throughput = each.value.throughput } : {},
          each.value.autoscale_settings != null ? {
            autoscaleSettings = {
              maxThroughput = each.value.autoscale_settings.max_throughput
            }
          } : {}
        )
      } : {}
    )
  }

  tags                   = var.tags
  ignore_body_changes    = length(var.ignore_body_changes.documentdb_database_accounts_cassandra_keyspaces) > 0 ? var.ignore_body_changes.documentdb_database_accounts_cassandra_keyspaces : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "azapi_resource" "cassandra_tables" {
  for_each = local.cassandra_tables

  type      = var.resource_types.documentdb_database_accounts_cassandra_keyspaces_tables
  name      = each.value.table.name
  parent_id = azapi_resource.cassandra_keyspaces[each.value.keyspace_key].id

  body = {
    properties = merge(
      {
        resource = merge(
          {
            id = each.value.table.name
            schema = {
              columns = [
                for column in each.value.table.schema.columns : {
                  name = column.name
                  type = column.type
                }
              ]
              partitionKeys = [
                for partition_key in each.value.table.schema.partition_keys : {
                  name = partition_key.name
                }
              ]
              clusterKeys = [
                for cluster_key in each.value.table.schema.cluster_keys : {
                  name    = cluster_key.name
                  orderBy = cluster_key.order_by
                }
              ]
            }
          },
          each.value.table.default_ttl == null ? {} : { defaultTtl = each.value.table.default_ttl },
          each.value.table.analytical_storage_ttl == null ? {} : { analyticalStorageTtl = each.value.table.analytical_storage_ttl }
        )
      },
      each.value.table.throughput != null || each.value.table.autoscale_settings != null ? {
        options = merge(
          each.value.table.throughput != null ? { throughput = each.value.table.throughput } : {},
          each.value.table.autoscale_settings != null ? {
            autoscaleSettings = {
              maxThroughput = each.value.table.autoscale_settings.max_throughput
            }
          } : {}
        )
      } : {}
    )
  }

  tags                   = var.tags
  ignore_body_changes    = length(var.ignore_body_changes.documentdb_database_accounts_cassandra_keyspaces_tables) > 0 ? var.ignore_body_changes.documentdb_database_accounts_cassandra_keyspaces_tables : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
