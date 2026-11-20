# Role definitions are resolved here, case-insensitively as the AzureRM provider did, rather than by the interfaces
# module, whose lookup is case-sensitive. They are listed in the resource group rather than on the account, so the
# lookup does not wait for pending changes to the account and a role name that does not exist fails during plan.
data "azapi_resource_list" "role_definitions" {
  count = length(local.total_role_assignments) > 0 ? 1 : 0

  parent_id = var.parent_id
  type      = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  response_export_values = {
    results = "value[].{id: id, role_name: properties.roleName}"
  }
}

module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.9.0"

  location                                  = var.location
  enable_telemetry                          = false
  role_assignment_definition_lookup_enabled = false
  role_assignments                          = local.role_assignments
}

resource "azapi_resource" "role_assignments" {
  for_each = local.total_role_assignments

  name                 = module.avm_interfaces.role_assignments_azapi[each.key].name
  parent_id            = each.value.scope_type == local.private_endpoint_scope_type ? local.private_endpoint_ids[each.value.pe_name] : azapi_resource.this.id
  type                 = var.resource_types.authorization_role_assignments
  body                 = module.avm_interfaces.role_assignments_azapi[each.key].body
  ignore_body_changes  = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  ignore_casing        = true
  ignore_null_property = true
  # The AzureRM provider replaced a role assignment whenever one of its inputs changed. The inputs are compared,
  # rather than body paths or the resolved role definition ID, because Azure normalises role definition IDs. While
  # the prior value is null, as it is straight after upgrading from AzureRM, nothing is replaced.
  replace_triggers_external_values = {
    condition                              = each.value.role_params.condition
    condition_version                      = each.value.role_params.condition_version
    delegated_managed_identity_resource_id = each.value.role_params.delegated_managed_identity_resource_id
    description                            = each.value.role_params.description
    name                                   = each.value.role_params.name
    principal_id                           = lower(each.value.role_params.principal_id)
    principal_type                         = local.role_assignments[each.key].principal_type
    role_definition_id_or_name             = lower(each.value.role_params.role_definition_id_or_name)
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
    # Upgraded assignments keep the GUID the AzureRM provider generated, while the interfaces module generates a new
    # one. Replacing them would fail under a `CanNotDelete` lock. A change to an explicit name still replaces the
    # assignment through replace_triggers_external_values.
    ignore_changes = [name]

    precondition {
      condition     = strcontains(lower(local.role_assignments[each.key].role_definition_id_or_name), local.role_definition_resource_substring)
      error_message = "The role definition `${each.value.role_params.role_definition_id_or_name}` was not found in the resource group. Use the name of a role definition that can be assigned there, or the role definition's resource ID."
    }
  }
}
