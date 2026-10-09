resource "azurerm_role_assignment" "this" {
  for_each = local.total_role_assignments

  principal_id = each.value.role_params.principal_id
  scope = (
    each.value.scope_type == local.private_endpoint_scope_type && var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups[each.value.pe_name].id :
    each.value.scope_type == local.private_endpoint_scope_type && var.private_endpoints_manage_dns_zone_group == false ? azurerm_private_endpoint.this_unmanaged_dns_zone_groups[each.value.pe_name].id :
    azurerm_cosmosdb_account.this.id
  )
  condition                              = each.value.role_params.condition
  condition_version                      = each.value.role_params.condition_version
  delegated_managed_identity_resource_id = each.value.role_params.delegated_managed_identity_resource_id
  description                            = each.value.role_params.description
  principal_type                         = each.value.role_params.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_params.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_params.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_params.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_params.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.role_params.skip_service_principal_aad_check
}
