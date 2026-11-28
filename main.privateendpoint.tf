resource "azapi_resource" "private_endpoints" {
  for_each = var.private_endpoints_manage_dns_zone_group ? var.private_endpoints : {}

  location  = each.value.location != null ? each.value.location : var.location
  name      = local.private_endpoint_names[each.key]
  parent_id = local.private_endpoint_parent_ids[each.key]
  type      = var.resource_types.network_private_endpoints
  body = {
    properties = local.private_endpoint_properties[each.key]
  }
  ignore_body_changes  = length(var.ignore_body_changes.network_private_endpoints) > 0 ? var.ignore_body_changes.network_private_endpoints : null
  ignore_casing        = true
  ignore_null_property = true
  # Azure can return the application security groups in a different order from the one they were sent in.
  list_unique_id_property = {
    "properties.applicationSecurityGroups" = "id"
  }
  # Azure fails a private endpoint operation while another operation on the account is in progress. The lock runs
  # the account's private endpoints one at a time, as the AzureRM provider did, and depends_on keeps them apart
  # from the operations on the account's databases, containers and throughput.
  locks                            = [azapi_resource.this.id]
  replace_triggers_external_values = local.private_endpoint_replace_triggers[each.key]
  response_export_values           = []
  retry                            = var.retry
  tags                             = local.private_endpoint_tags[each.key]

  dynamic "timeouts" {
    for_each = [local.private_endpoint_timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [
    azapi_resource.gremlin_databases,
    azapi_resource.gremlin_graphs,
    azapi_resource.mongo_collections,
    azapi_resource.mongo_databases,
    azapi_resource.sql_containers,
    azapi_resource.sql_databases,
    azapi_resource.sql_dedicated_gateway,
    azapi_resource.sql_functions,
    azapi_resource.sql_stored_procedures,
    azapi_resource.sql_triggers,
    azapi_update_resource.gremlin_database_throughput,
    azapi_update_resource.gremlin_graph_throughput,
    azapi_update_resource.mongo_collection_throughput,
    azapi_update_resource.mongo_database_throughput,
    azapi_update_resource.sql_container_throughput,
    azapi_update_resource.sql_database_throughput,
  ]
}

# Private endpoints whose DNS zone group is managed outside this module, for example by Azure Policy.
resource "azapi_resource" "private_endpoints_unmanaged" {
  for_each = var.private_endpoints_manage_dns_zone_group ? {} : var.private_endpoints

  location  = each.value.location != null ? each.value.location : var.location
  name      = local.private_endpoint_names[each.key]
  parent_id = local.private_endpoint_parent_ids[each.key]
  type      = var.resource_types.network_private_endpoints
  body = {
    properties = local.private_endpoint_properties[each.key]
  }
  ignore_body_changes  = length(var.ignore_body_changes.network_private_endpoints) > 0 ? var.ignore_body_changes.network_private_endpoints : null
  ignore_casing        = true
  ignore_null_property = true
  # Azure can return the application security groups in a different order from the one they were sent in.
  list_unique_id_property = {
    "properties.applicationSecurityGroups" = "id"
  }
  # The same lock and dependencies as for `azapi_resource.private_endpoints`.
  locks                            = [azapi_resource.this.id]
  replace_triggers_external_values = local.private_endpoint_replace_triggers[each.key]
  response_export_values           = []
  retry                            = var.retry
  tags                             = local.private_endpoint_tags[each.key]

  dynamic "timeouts" {
    for_each = [local.private_endpoint_timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [
    azapi_resource.gremlin_databases,
    azapi_resource.gremlin_graphs,
    azapi_resource.mongo_collections,
    azapi_resource.mongo_databases,
    azapi_resource.sql_containers,
    azapi_resource.sql_databases,
    azapi_resource.sql_dedicated_gateway,
    azapi_resource.sql_functions,
    azapi_resource.sql_stored_procedures,
    azapi_resource.sql_triggers,
    azapi_update_resource.gremlin_database_throughput,
    azapi_update_resource.gremlin_graph_throughput,
    azapi_update_resource.mongo_collection_throughput,
    azapi_update_resource.mongo_database_throughput,
    azapi_update_resource.sql_container_throughput,
    azapi_update_resource.sql_database_throughput,
  ]
}

resource "azapi_resource" "private_dns_zone_groups" {
  for_each = local.private_dns_zone_groups

  name      = each.value.name
  parent_id = azapi_resource.private_endpoints[each.key].id
  type      = var.resource_types.network_private_endpoints_private_dns_zone_groups
  body = {
    properties = {
      privateDnsZoneConfigs = [
        for private_dns_zone_resource_id in each.value.private_dns_zone_resource_ids : {
          name = element(reverse(split("/", private_dns_zone_resource_id)), 0)
          properties = {
            privateDnsZoneId = private_dns_zone_resource_id
          }
        }
      ]
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups) > 0 ? var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups : null
  ignore_casing          = true
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

# Adopts the zone groups that versions 0.12.x and earlier created as part of the private endpoint, so that
# upgrading does not fail with `Resource already exists`. The gate is required: on a new deployment the zone
# group does not exist yet and an unconditional import fails at plan time. Terraform skips an import whose
# target is already in state, so leaving the flag set after the upgrade is a no-op for those zone groups.
import {
  for_each = var.avm_managed_migration_enabled ? local.private_dns_zone_group_imports : {}

  to = azapi_resource.private_dns_zone_groups[each.key]
  id = each.value
}
