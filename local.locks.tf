locals {
  none_lock_kind = "None"

  pe_locks = {
    for pe_name, pe_params in local.normalized_private_endpoints :
    "${local.private_endpoint_scope_type}|${pe_name}" => {
      pe_name    = pe_name
      scope_type = local.private_endpoint_scope_type
      lock       = pe_params.lock != null ? pe_params.lock : var.lock
    }
  }

  filtered_pe_locks = {
    for k, v in local.pe_locks :
    k => v
    if try(v.lock.kind, local.none_lock_kind) != local.none_lock_kind
  }

  namespace_lock = var.lock != null ? {
    (local.namespace_scope_type) = {
      lock       = var.lock
      scope_type = local.namespace_scope_type
    }
  } : {}

  total_locks = merge(local.filtered_pe_locks, local.namespace_lock)
}
