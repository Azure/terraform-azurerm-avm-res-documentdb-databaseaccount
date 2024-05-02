locals {
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

  topic_scope_type            = "Topic"
  queue_scope_type            = "Queue"
  namespace_scope_type        = "Namespace"
  private_endpoint_scope_type = "PrivateEndpoint"

  basic_sku_name    = "Basic"
  premium_sku_name  = "Premium"
  standard_sku_name = "Standard"

  smallest_premium_max_message_size_in_kilobytes = 1024
  biggest_premium_max_message_size_in_kilobytes  = 102400

  normalized_capacity = var.sku != local.premium_sku_name ? 0 : coalesce(var.capacity, 1)

  normalized_zone_redundant = var.sku != local.premium_sku_name ? false : coalesce(var.zone_redundant, true)

  normalized_premium_messaging_partitions = var.sku != local.premium_sku_name ? 0 : coalesce(var.premium_messaging_partitions, 1)

  customer_managed_key_keyvault_name = var.customer_managed_key != null ? element(split("/", var.customer_managed_key.key_vault_resource_id), 8) : null

  normalized_cmk_key_url = var.customer_managed_key != null ? "https://${local.customer_managed_key_keyvault_name}.vault.azure.net/keys/${var.customer_managed_key.key_name}/${var.customer_managed_key.key_version != null ? var.customer_managed_key.key_version : ""}" : null
}
