resource "azurerm_management_lock" "this" {
  for_each = local.total_locks

  scope = (
    each.value.scope_type == local.private_endpoint_scope_type && var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups[each.value.pe_name].id :
    each.value.scope_type == local.private_endpoint_scope_type && var.private_endpoints_manage_dns_zone_group == false ? azurerm_private_endpoint.this_unmanaged_dns_zone_groups[each.value.pe_name].id :
    azurerm_servicebus_namespace.this.id
  )

  name = coalesce(each.value.lock.name, "lock-${each.value.lock.kind}")

  lock_level = each.value.lock.kind
  notes      = each.value.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."

  depends_on = [
    azurerm_servicebus_namespace.this,
    azurerm_monitor_diagnostic_setting.this, azurerm_role_assignment.this,
    azurerm_private_endpoint_application_security_group_association.this,
    azurerm_servicebus_namespace_authorization_rule.this,
    azurerm_servicebus_queue.base_queues, azurerm_servicebus_queue.forward_queues, azurerm_servicebus_queue_authorization_rule.this,
    azurerm_servicebus_topic.this, azurerm_servicebus_topic_authorization_rule.this, azurerm_servicebus_subscription.base_topics, azurerm_servicebus_subscription.forward_topics,
    azurerm_private_endpoint.this_managed_dns_zone_groups, azurerm_private_endpoint.this_unmanaged_dns_zone_groups
  ]
}
