locals {
  role_definition_resource_substring = "providers/Microsoft.Authorization/roleDefinitions"

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
