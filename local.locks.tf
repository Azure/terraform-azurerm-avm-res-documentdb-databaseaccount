locals {
  account_lock = var.lock != null ? {
    (local.account_scope_type) = {
      lock       = var.lock
      scope_type = local.account_scope_type
    }
  } : {}
  filtered_pe_locks = {
    for k, v in local.pe_locks :
    k => v
    if try(v.lock.kind, local.none_lock_kind) != local.none_lock_kind
  }
  none_lock_kind = "None"
  pe_locks = {
    for pe_name, pe_params in var.private_endpoints :
    "${local.private_endpoint_scope_type}|${pe_name}" => {
      pe_name    = pe_name
      scope_type = local.private_endpoint_scope_type
      lock       = pe_params.lock != null ? pe_params.lock : var.lock
    }
  }
  total_locks = merge(local.filtered_pe_locks, local.account_lock)
}

locals {
  # The notes this module has always written, so that upgrading leaves existing locks unchanged.
  lock_notes = {
    CanNotDelete = "Cannot delete the resource or its child resources."
    ReadOnly     = "Cannot delete or modify the resource or its child resources."
  }
  # The scope of each lock: the account, or one of its private endpoints.
  lock_scopes = {
    for key, lock in local.total_locks : key => lock.scope_type == local.private_endpoint_scope_type ? local.private_endpoint_ids[lock.pe_name] : azapi_resource.this.id
  }
}
