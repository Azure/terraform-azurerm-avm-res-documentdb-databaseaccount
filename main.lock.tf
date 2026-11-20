resource "azapi_resource" "locks" {
  for_each = local.total_locks

  name      = coalesce(each.value.lock.name, "lock-${each.value.lock.kind}")
  parent_id = local.lock_scopes[each.key]
  type      = var.resource_types.authorization_locks
  body = {
    properties = {
      level = each.value.lock.kind
      notes = coalesce(each.value.lock.notes, local.lock_notes[each.value.lock.kind])
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
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

  # Create the locks last and remove them first. A `ReadOnly` lock blocks changes to the resources under it, and a
  # `CanNotDelete` lock blocks deleting them.
  depends_on = [time_sleep.lock_removal]
}

# Azure keeps enforcing a deleted lock for a few seconds, and the AzAPI provider does not wait for it to be gone as
# the AzureRM provider did. These pauses are destroyed after the locks and before the resources under them, so they
# are not deleted while a lock still applies.
resource "time_sleep" "lock_removal" {
  for_each = local.total_locks

  destroy_duration = "30s"
  # Replacing the locked resource replaces its lock, so the pause is replaced with them.
  triggers = {
    scope_id = local.lock_scopes[each.key]
  }

  depends_on = [
    azapi_resource.diagnostic_settings,
    azapi_resource.gremlin_databases,
    azapi_resource.gremlin_graphs,
    azapi_resource.mongo_collections,
    azapi_resource.mongo_databases,
    azapi_resource.private_dns_zone_groups,
    azapi_resource.private_endpoints,
    azapi_resource.private_endpoints_unmanaged,
    azapi_resource.role_assignments,
    azapi_resource.sql_containers,
    azapi_resource.sql_databases,
    azapi_resource.sql_dedicated_gateway,
    azapi_resource.sql_functions,
    azapi_resource.sql_stored_procedures,
    azapi_resource.sql_triggers,
    azapi_resource_action.secrets,
    azapi_update_resource.gremlin_database_throughput,
    azapi_update_resource.gremlin_graph_throughput,
    azapi_update_resource.mongo_collection_throughput,
    azapi_update_resource.mongo_database_throughput,
    azapi_update_resource.sql_container_throughput,
    azapi_update_resource.sql_database_throughput,
  ]
}
