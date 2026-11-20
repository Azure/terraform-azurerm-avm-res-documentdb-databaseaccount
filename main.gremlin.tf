# Azure accepts tags on this Cosmos DB resource but does not store them, so setting them would show a change on
# every plan.
# tflint-ignore: avm_azapi_resource_tags_required
resource "azapi_resource" "gremlin_databases" {
  for_each = var.gremlin_databases

  name      = each.value.name
  parent_id = azapi_resource.this.id
  type      = var.resource_types.documentdb_database_accounts_gremlin_databases
  body = {
    properties = {
      options = local.throughput_options["gremlin_database|${each.key}"]
      resource = {
        id = each.value.name
      }
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.documentdb_database_accounts_gremlin_databases) > 0 ? var.ignore_body_changes.documentdb_database_accounts_gremlin_databases : null
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
resource "azapi_resource" "gremlin_graphs" {
  for_each = local.gremlin_graphs

  name      = each.value.graph_params.name
  parent_id = azapi_resource.gremlin_databases[each.value.db_name].id
  type      = var.resource_types.documentdb_database_accounts_gremlin_databases_graphs
  body = {
    properties = {
      options  = local.throughput_options["gremlin_graph|${each.key}"]
      resource = local.gremlin_graph_resources[each.key]
    }
  }
  ignore_body_changes  = length(var.ignore_body_changes.documentdb_database_accounts_gremlin_databases_graphs) > 0 ? var.ignore_body_changes.documentdb_database_accounts_gremlin_databases_graphs : null
  ignore_casing        = true
  ignore_null_property = true
  # The AzureRM provider sent the included and excluded paths in the order of its hash sets, and Azure kept that
  # order. The paths are matched by value, so a different order is not a change.
  list_unique_id_property = {
    "properties.resource.indexingPolicy.excludedPaths"  = "path"
    "properties.resource.indexingPolicy.includedPaths"  = "path"
    "properties.resource.indexingPolicy.spatialIndexes" = "path"
  }
  # The AzureRM provider replaced the graph when one of these settings changed, because Azure cannot change them in
  # place. While the prior value is null, as it is straight after upgrading from AzureRM, nothing is replaced.
  replace_triggers_external_values = {
    conflict_resolution_policy = each.value.graph_params.conflict_resolution_policy
    partition_key_path         = each.value.graph_params.partition_key_path
    partition_key_version      = each.value.graph_params.partition_key_version
    unique_key                 = each.value.graph_params.unique_key == null ? null : sort(each.value.graph_params.unique_key.paths)
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
    # Throughput is set when the graph is created, and later changes go through `throughputSettings`. Azure cannot
    # change the conflict resolution policy or the unique keys, so updates send back the values Azure has, and a
    # change replaces the graph.
    ignore_changes = [
      body.properties.options,
      body.properties.resource.conflictResolutionPolicy,
      body.properties.resource.uniqueKeyPolicy,
    ]
  }
}
