locals {
  account_role_assignments = {
    for role_key, role_params in var.role_assignments :
    "${local.account_scope_type}|${role_key}" => {
      role_params = role_params
      scope_type  = local.account_scope_type
    }
  }
  flatten_pe_role_assignments = flatten([
    for pe_name, pe_params in var.private_endpoints : [
      for role_key, role_params in pe_params.role_assignments : {
        role_key    = role_key
        pe_name     = pe_name
        role_params = role_params
        scope_type  = local.private_endpoint_scope_type
      }
    ]
  ])
  pe_role_assignments = {
    for pe_role in local.flatten_pe_role_assignments :
    "${pe_role.scope_type}|${pe_role.role_key}" => pe_role
  }
  total_role_assignments = merge(local.account_role_assignments, local.pe_role_assignments)
}

locals {
  # Role names are matched case-insensitively, as the AzureRM provider matched them.
  role_definition_ids_by_name = length(local.total_role_assignments) > 0 ? {
    for definition in data.azapi_resource_list.role_definitions[0].output.results : lower(definition.role_name) => definition.id...
  } : {}
  role_definition_resource_substring = "/providers/microsoft.authorization/roledefinitions/"
  role_assignments = {
    for key, assignment in local.total_role_assignments : key => merge(assignment.role_params, {
      # The AzureRM provider sent this principal type when the flag was set, which skips the Entra ID existence
      # check that fails for newly created service principals.
      principal_type = assignment.role_params.principal_type == null && assignment.role_params.skip_service_principal_aad_check ? "ServicePrincipal" : assignment.role_params.principal_type
      # Names resolve to IDs. Tenant-level IDs are qualified with the subscription, which is the form Azure returns,
      # so that the configuration and the deployed assignment compare equal.
      role_definition_id_or_name = (
        !strcontains(lower(assignment.role_params.role_definition_id_or_name), local.role_definition_resource_substring) ? try(local.role_definition_ids_by_name[lower(assignment.role_params.role_definition_id_or_name)][0], assignment.role_params.role_definition_id_or_name) :
        startswith(lower(assignment.role_params.role_definition_id_or_name), "/providers/") ? "/subscriptions/${local.subscription_id}${assignment.role_params.role_definition_id_or_name}" :
        assignment.role_params.role_definition_id_or_name
      )
    })
  }
}
