resource "azurerm_management_lock" "this" {
  for_each = local.total_locks

  lock_level = each.value.lock.kind
  name       = coalesce(each.value.lock.name, "lock-${each.value.lock.kind}")
  scope = (
    each.value.scope_type == local.private_endpoint_scope_type && var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups[each.value.pe_name].id :
    each.value.scope_type == local.private_endpoint_scope_type && var.private_endpoints_manage_dns_zone_group == false ? azurerm_private_endpoint.this_unmanaged_dns_zone_groups[each.value.pe_name].id :
    azurerm_cosmosdb_account.this.id
  )
  notes = each.value.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."

  depends_on = [
    azurerm_cosmosdb_account.this,

    azurerm_monitor_diagnostic_setting.this, azurerm_role_assignment.this,
    azurerm_private_endpoint_application_security_group_association.this,
    azurerm_private_endpoint.this_managed_dns_zone_groups, azurerm_private_endpoint.this_unmanaged_dns_zone_groups
  ]
}
