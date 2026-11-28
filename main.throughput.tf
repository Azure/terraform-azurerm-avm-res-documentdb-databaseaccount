# Throughput is set when a database, container, collection or graph is created. Later changes are sent to its
# throughput settings, as the AzureRM provider sent them. Upgrading from an earlier version sends the throughput
# that is already set.
resource "azapi_update_resource" "sql_database_throughput" {
  for_each = { for key in keys(var.sql_databases) : key => local.throughput_resources["sql_database|${key}"] if contains(keys(local.throughput_resources), "sql_database|${key}") }

  name      = "default"
  parent_id = azapi_resource.sql_databases[each.key].id
  type      = var.resource_types.documentdb_database_accounts_sql_databases_throughput_settings
  body = {
    properties = {
      resource = each.value
    }
  }
  response_export_values = []
  retry                  = var.retry
  # The body is merged into the current throughput settings, which hold a throughput even when autoscale is set.
  # Clearing it keeps Azure from taking an autoscale update as a switch to manual throughput.
  sensitive_body = contains(keys(each.value), "autoscaleSettings") ? { properties = { resource = { throughput = null } } } : null

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

resource "azapi_update_resource" "sql_container_throughput" {
  for_each = { for key in keys(local.sql_containers) : key => local.throughput_resources["sql_container|${key}"] if contains(keys(local.throughput_resources), "sql_container|${key}") }

  name      = "default"
  parent_id = azapi_resource.sql_containers[each.key].id
  type      = var.resource_types.documentdb_database_accounts_sql_databases_containers_throughput_settings
  body = {
    properties = {
      resource = each.value
    }
  }
  response_export_values = []
  retry                  = var.retry
  # The body is merged into the current throughput settings, which hold a throughput even when autoscale is set.
  # Clearing it keeps Azure from taking an autoscale update as a switch to manual throughput.
  sensitive_body = contains(keys(each.value), "autoscaleSettings") ? { properties = { resource = { throughput = null } } } : null

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

resource "azapi_update_resource" "mongo_database_throughput" {
  for_each = { for key in keys(var.mongo_databases) : key => local.throughput_resources["mongo_database|${key}"] if contains(keys(local.throughput_resources), "mongo_database|${key}") }

  name      = "default"
  parent_id = azapi_resource.mongo_databases[each.key].id
  type      = var.resource_types.documentdb_database_accounts_mongodb_databases_throughput_settings
  body = {
    properties = {
      resource = each.value
    }
  }
  response_export_values = []
  retry                  = var.retry
  # The body is merged into the current throughput settings, which hold a throughput even when autoscale is set.
  # Clearing it keeps Azure from taking an autoscale update as a switch to manual throughput.
  sensitive_body = contains(keys(each.value), "autoscaleSettings") ? { properties = { resource = { throughput = null } } } : null

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

resource "azapi_update_resource" "mongo_collection_throughput" {
  for_each = { for key in keys(local.mongodb_collections) : key => local.throughput_resources["mongo_collection|${key}"] if contains(keys(local.throughput_resources), "mongo_collection|${key}") }

  name      = "default"
  parent_id = azapi_resource.mongo_collections[each.key].id
  type      = var.resource_types.documentdb_database_accounts_mongodb_databases_collections_throughput_settings
  body = {
    properties = {
      resource = each.value
    }
  }
  response_export_values = []
  retry                  = var.retry
  # The body is merged into the current throughput settings, which hold a throughput even when autoscale is set.
  # Clearing it keeps Azure from taking an autoscale update as a switch to manual throughput.
  sensitive_body = contains(keys(each.value), "autoscaleSettings") ? { properties = { resource = { throughput = null } } } : null

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

resource "azapi_update_resource" "gremlin_database_throughput" {
  for_each = { for key in keys(var.gremlin_databases) : key => local.throughput_resources["gremlin_database|${key}"] if contains(keys(local.throughput_resources), "gremlin_database|${key}") }

  name      = "default"
  parent_id = azapi_resource.gremlin_databases[each.key].id
  type      = var.resource_types.documentdb_database_accounts_gremlin_databases_throughput_settings
  body = {
    properties = {
      resource = each.value
    }
  }
  response_export_values = []
  retry                  = var.retry
  # The body is merged into the current throughput settings, which hold a throughput even when autoscale is set.
  # Clearing it keeps Azure from taking an autoscale update as a switch to manual throughput.
  sensitive_body = contains(keys(each.value), "autoscaleSettings") ? { properties = { resource = { throughput = null } } } : null

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

resource "azapi_update_resource" "gremlin_graph_throughput" {
  for_each = { for key in keys(local.gremlin_graphs) : key => local.throughput_resources["gremlin_graph|${key}"] if contains(keys(local.throughput_resources), "gremlin_graph|${key}") }

  name      = "default"
  parent_id = azapi_resource.gremlin_graphs[each.key].id
  type      = var.resource_types.documentdb_database_accounts_gremlin_databases_graphs_throughput_settings
  body = {
    properties = {
      resource = each.value
    }
  }
  response_export_values = []
  retry                  = var.retry
  # The body is merged into the current throughput settings, which hold a throughput even when autoscale is set.
  # Clearing it keeps Azure from taking an autoscale update as a switch to manual throughput.
  sensitive_body = contains(keys(each.value), "autoscaleSettings") ? { properties = { resource = { throughput = null } } } : null

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
