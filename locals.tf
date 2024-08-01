locals {
  account_scope_type            = "Account"
  cmk_keyvault_name             = var.customer_managed_key != null ? element(split("/", var.customer_managed_key.key_vault_resource_id), 8) : null
  consistent_prefix_consistency = "ConsistentPrefix"
  continuous_backup_policy      = "Continuous"
  default_geo_location = toset([{
    failover_priority = 0
    zone_redundant    = true
    location          = var.location
  }])
  managed_identities = {
    system_assigned_user_assigned = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? {
      this = {
        type                       = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
    system_assigned = var.managed_identities.system_assigned ? {
      this = {
        type = "SystemAssigned"
      }
    } : {}
    user_assigned = length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      this = {
        type                       = "UserAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
  }
  normalized_cmk_default_identity_type = var.customer_managed_key != null ? "UserAssignedIdentity=${var.customer_managed_key.user_assigned_identity.resource_id}" : null
  normalized_cmk_key_url               = var.customer_managed_key != null ? "https://${local.cmk_keyvault_name}.vault.azure.net/keys/${var.customer_managed_key.key_name}" : null
  normalized_geo_locations             = coalesce(var.geo_locations, local.default_geo_location)
  normalized_ip_range_filter           = length(local.trimmed_ip_range_filter) > 0 ? join(",", local.trimmed_ip_range_filter) : null
  periodic_backup_policy               = "Periodic"
  private_endpoint_scope_type          = "PrivateEndpoint"
  serverless_capability                = "EnableServerless"
  trimmed_ip_range_filter              = [for value in var.ip_range_filter : trimspace(value)]
}
