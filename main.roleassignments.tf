resource "azurerm_role_assignment" "this" {
  for_each = local.total_role_assignments

  scope = (
    each.value.scope_type == local.queue_scope_type ? try(azurerm_servicebus_queue.base_queues[each.value.queue_name].id, azurerm_servicebus_queue.forward_queues[each.value.queue_name].id) :
    each.value.scope_type == local.topic_scope_type ? try(azurerm_servicebus_topic.this[each.value.topic_name].id) :
    each.value.scope_type == local.private_endpoint_scope_type && var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups[each.value.pe_name].id :
    each.value.scope_type == local.private_endpoint_scope_type && var.private_endpoints_manage_dns_zone_group == false ? azurerm_private_endpoint.this_unmanaged_dns_zone_groups[each.value.pe_name].id :
    azurerm_servicebus_namespace.this.id
  )

  role_definition_name = strcontains(lower(each.value.role_params.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_params.role_definition_id_or_name
  role_definition_id   = strcontains(lower(each.value.role_params.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_params.role_definition_id_or_name : null

  principal_id                           = each.value.role_params.principal_id
  skip_service_principal_aad_check       = each.value.role_params.skip_service_principal_aad_check
  delegated_managed_identity_resource_id = each.value.role_params.delegated_managed_identity_resource_id
}
