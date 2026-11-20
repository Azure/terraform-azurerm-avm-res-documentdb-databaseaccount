# Azure accepts tags on this Cosmos DB resource but does not store them, so setting them would show a change on
# every plan.
# tflint-ignore: avm_azapi_resource_tags_required
resource "azapi_resource" "mongo_databases" {
  for_each = var.mongo_databases

  name      = each.value.name
  parent_id = azapi_resource.this.id
  type      = var.resource_types.documentdb_database_accounts_mongodb_databases
  body = {
    properties = {
      options = local.throughput_options["mongo_database|${each.key}"]
      resource = {
        id = each.value.name
      }
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.documentdb_database_accounts_mongodb_databases) > 0 ? var.ignore_body_changes.documentdb_database_accounts_mongodb_databases : null
  ignore_null_property   = true
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    # Throughput is set when the database is created. Later changes go through `throughputSettings`, as with the
    # AzureRM provider.
    ignore_changes = [body.properties.options]
  }
}

# Azure accepts tags on this Cosmos DB resource but does not store them, so setting them would show a change on
# every plan.
# tflint-ignore: avm_azapi_resource_tags_required
resource "azapi_resource" "mongo_collections" {
  for_each = local.mongodb_collections

  name      = each.value.collection_name
  parent_id = azapi_resource.mongo_databases[each.value.db_name].id
  type      = var.resource_types.documentdb_database_accounts_mongodb_databases_collections
  body = {
    properties = {
      options  = local.throughput_options["mongo_collection|${each.key}"]
      resource = local.mongo_collection_resources[each.key]
    }
  }
  ignore_body_changes  = length(var.ignore_body_changes.documentdb_database_accounts_mongodb_databases_collections) > 0 ? var.ignore_body_changes.documentdb_database_accounts_mongodb_databases_collections : null
  ignore_null_property = true
  # The AzureRM provider replaced the collection when its shard key changed. While the prior value is null, as it is
  # straight after upgrading from AzureRM, nothing is replaced.
  replace_triggers_external_values = {
    shard_key = each.value.collection_params.shard_key
  }
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    # Throughput is set when the collection is created. Later changes go through `throughputSettings`, as with the
    # AzureRM provider. Azure cannot change the shard key, so updates send back the one Azure has.
    ignore_changes = [
      body.properties.options,
      body.properties.resource.shardKey,
    ]
  }
}
