resource "azurerm_cosmosdb_mongo_database" "this" {
  for_each = var.mongo_databases

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

resource "azurerm_cosmosdb_mongo_collection" "this" {
  for_each = local.mongodb_collections

  account_name        = azurerm_cosmosdb_account.this.name
  database_name       = azurerm_cosmosdb_mongo_database.this[each.value.db_name].name
  name                = each.value.collection_name
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
  default_ttl_seconds = each.value.collection_params.default_ttl_seconds
  shard_key           = each.value.collection_params.shard_key
  throughput          = each.value.collection_params.throughput

  dynamic "autoscale_settings" {
    for_each = try(each.value.collection_params.autoscale_settings.max_throughput, null) != null ? [1] : []

    content {
      max_throughput = each.value.collection_params.autoscale_settings.max_throughput
    }
  }
  dynamic "index" {
    for_each = each.value.collection_params.index != null ? [each.value.collection_params.index] : []

    content {
      keys   = index.value.keys
      unique = index.value.unique
    }
  }
}

