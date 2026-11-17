# Azure accepts tags on this Cosmos DB resource but does not store them, so setting them would show a change on
# every plan.
# tflint-ignore: avm_azapi_resource_tags_required
resource "azapi_resource" "sql_databases" {
  for_each = var.sql_databases

  name      = each.value.name
  parent_id = azapi_resource.this.id
  type      = var.resource_types.documentdb_database_accounts_sql_databases
  body = {
    properties = {
      options = local.throughput_options["sql_database|${each.key}"]
      resource = {
        id = each.value.name
      }
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.documentdb_database_accounts_sql_databases) > 0 ? var.ignore_body_changes.documentdb_database_accounts_sql_databases : null
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

    precondition {
      condition     = contains(var.capabilities[*].name, local.serverless_capability) && (each.value.throughput != null || try(each.value.autoscale_settings.max_throughput, null) != null) ? false : true
      error_message = "Serverless containers must not specify 'throughput' or 'autoscale_settings.max_throughput' at the database level."
    }
  }
}

# Azure accepts tags on this Cosmos DB resource but does not store them, so setting them would show a change on
# every plan.
# tflint-ignore: avm_azapi_resource_tags_required
resource "azapi_resource" "sql_containers" {
  for_each = local.sql_containers

  name      = each.value.container_name
  parent_id = azapi_resource.sql_databases[each.value.db_name].id
  type      = var.resource_types.documentdb_database_accounts_sql_databases_containers
  body = {
    properties = {
      options  = local.throughput_options["sql_container|${each.key}"]
      resource = local.sql_container_resources[each.key]
    }
  }
  ignore_body_changes  = length(var.ignore_body_changes.documentdb_database_accounts_sql_databases_containers) > 0 ? var.ignore_body_changes.documentdb_database_accounts_sql_databases_containers : null
  ignore_casing        = true
  ignore_null_property = true
  list_unique_id_property = {
    "properties.resource.indexingPolicy.excludedPaths"  = "path"
    "properties.resource.indexingPolicy.includedPaths"  = "path"
    "properties.resource.indexingPolicy.spatialIndexes" = "path"
  }
  # The AzureRM provider replaced the container when one of these settings changed, because Azure cannot change
  # them in place. While the prior value is null, as it is straight after upgrading from AzureRM, nothing is
  # replaced.
  replace_triggers_external_values = {
    conflict_resolution_policy = each.value.container_params.conflict_resolution_policy
    partition_key_paths        = each.value.container_params.partition_key_paths
    # An unset version is version 1 in Azure, so setting it to 1 does not replace the container.
    partition_key_version = coalesce(each.value.container_params.partition_key_version, 1)
    unique_keys           = sort([for unique_key in each.value.container_params.unique_keys : join(",", sort(unique_key.paths))])
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
    # Throughput is set when the container is created, and later changes go through `throughputSettings`. Azure
    # cannot change the conflict resolution policy or the unique keys, so updates send back the values Azure has,
    # in the order it has them, and a change replaces the container.
    ignore_changes = [
      body.properties.options,
      body.properties.resource.conflictResolutionPolicy,
      body.properties.resource.uniqueKeyPolicy,
    ]

    precondition {
      condition     = contains(var.capabilities[*].name, local.serverless_capability) && (each.value.container_params.throughput != null || try(each.value.container_params.autoscale_settings.max_throughput, null) != null) ? false : true
      error_message = "Serverless containers must not specify 'throughput' or 'autoscale_settings.max_throughput' at the container level."
    }
  }
}

# Azure accepts tags on this Cosmos DB resource but does not store them, so setting them would show a change on
# every plan.
# tflint-ignore: avm_azapi_resource_tags_required
resource "azapi_resource" "sql_functions" {
  for_each = local.sql_container_functions

  name      = each.value.function_name
  parent_id = azapi_resource.sql_containers[each.value.container_key].id
  type      = var.resource_types.documentdb_database_accounts_sql_databases_containers_user_defined_functions
  body = {
    properties = {
      options = {}
      resource = {
        body = each.value.function_params.body
        id   = each.value.function_name
      }
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.documentdb_database_accounts_sql_databases_containers_user_defined_functions) > 0 ? var.ignore_body_changes.documentdb_database_accounts_sql_databases_containers_user_defined_functions : null
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
}

# Azure accepts tags on this Cosmos DB resource but does not store them, so setting them would show a change on
# every plan.
# tflint-ignore: avm_azapi_resource_tags_required
resource "azapi_resource" "sql_stored_procedures" {
  for_each = local.sql_container_stored_procedures

  name      = each.value.stored_name
  parent_id = azapi_resource.sql_containers[each.value.container_key].id
  type      = var.resource_types.documentdb_database_accounts_sql_databases_containers_stored_procedures
  body = {
    properties = {
      options = {}
      resource = {
        body = each.value.stored_params.body
        id   = each.value.stored_name
      }
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.documentdb_database_accounts_sql_databases_containers_stored_procedures) > 0 ? var.ignore_body_changes.documentdb_database_accounts_sql_databases_containers_stored_procedures : null
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
}

# Azure accepts tags on this Cosmos DB resource but does not store them, so setting them would show a change on
# every plan.
# tflint-ignore: avm_azapi_resource_tags_required
resource "azapi_resource" "sql_triggers" {
  for_each = local.sql_container_triggers

  name      = each.value.trigger_name
  parent_id = azapi_resource.sql_containers[each.value.container_key].id
  type      = var.resource_types.documentdb_database_accounts_sql_databases_containers_triggers
  body = {
    properties = {
      options = {}
      resource = {
        body             = each.value.trigger_params.body
        id               = each.value.trigger_name
        triggerOperation = each.value.trigger_params.operation
        triggerType      = each.value.trigger_params.type
      }
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.documentdb_database_accounts_sql_databases_containers_triggers) > 0 ? var.ignore_body_changes.documentdb_database_accounts_sql_databases_containers_triggers : null
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
}

resource "azapi_resource" "sql_dedicated_gateway" {
  count = var.sql_dedicated_gateway != null && length(var.sql_databases) > 0 ? 1 : 0

  name      = "SqlDedicatedGateway"
  parent_id = azapi_resource.this.id
  type      = var.resource_types.documentdb_database_accounts_services
  body = {
    properties = {
      instanceCount = var.sql_dedicated_gateway.instance_count
      instanceSize  = var.sql_dedicated_gateway.instance_size
      serviceType   = "SqlDedicatedGateway"
    }
  }
  ignore_body_changes = length(var.ignore_body_changes.documentdb_database_accounts_services) > 0 ? var.ignore_body_changes.documentdb_database_accounts_services : null
  # The AzureRM provider replaced the gateway when its size changed.
  replace_triggers_refs = [
    "properties.instanceSize",
  ]
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
}
