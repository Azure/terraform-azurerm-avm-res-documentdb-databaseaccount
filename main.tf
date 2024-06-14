resource "azurerm_cosmosdb_account" "this" {
  name = var.name

  tags                = var.tags
  location            = var.location
  resource_group_name = var.resource_group_name

  free_tier_enabled          = var.free_tier_enabled
  minimal_tls_version        = var.minimal_tls_version
  partition_merge_enabled    = var.partition_merge_enabled
  analytical_storage_enabled = var.analytical_storage_enabled

  automatic_failover_enabled       = var.automatic_failover_enabled
  multiple_write_locations_enabled = var.backup.type == local.periodic_backup_policy ? var.multiple_write_locations_enabled : false

  local_authentication_disabled      = var.local_authentication_disabled
  access_key_metadata_writes_enabled = var.access_key_metadata_writes_enabled

  network_acl_bypass_ids                = var.network_acl_bypass_ids
  ip_range_filter                       = local.normalized_ip_range_filter
  public_network_access_enabled         = var.public_network_access_enabled
  network_acl_bypass_for_azure_services = var.network_acl_bypass_for_azure_services
  is_virtual_network_filter_enabled     = length(var.virtual_network_rules) > 0 ? true : false

  offer_type = "Standard"
  kind       = "GlobalDocumentDB"

  key_vault_key_id      = local.normalized_cmk_key_url
  default_identity_type = local.normalized_cmk_default_identity_type

  consistency_policy {
    consistency_level       = var.consistency_policy.consistency_level
    max_staleness_prefix    = var.consistency_policy.consistency_level == local.consistent_prefix_consistency ? var.consistency_policy.max_staleness_prefix : null
    max_interval_in_seconds = var.consistency_policy.consistency_level == local.consistent_prefix_consistency ? var.consistency_policy.max_interval_in_seconds : null
  }

  dynamic "geo_location" {
    for_each = local.normalized_geo_locations

    content {
      location          = geo_location.value.location
      zone_redundant    = geo_location.value.zone_redundant
      failover_priority = geo_location.value.failover_priority
    }
  }

  dynamic "identity" {
    for_each = local.managed_identities.system_assigned_user_assigned

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }

  backup {
    type                = var.backup.type
    tier                = var.backup.type == local.continuous_backup_policy ? var.backup.tier : null
    interval_in_minutes = var.backup.type == local.periodic_backup_policy ? var.backup.interval_in_minutes : null
    retention_in_hours  = var.backup.type == local.periodic_backup_policy ? var.backup.retention_in_hours : null
    storage_redundancy  = var.backup.type == local.periodic_backup_policy ? var.backup.storage_redundancy : null
  }

  capacity {
    total_throughput_limit = var.capacity.total_throughput_limit
  }

  dynamic "analytical_storage" {
    for_each = var.analytical_storage_config != null ? [1] : []

    content {
      schema_type = var.analytical_storage_config.schema_type
    }
  }

  dynamic "cors_rule" {
    for_each = var.cors_rule != null ? [1] : []

    content {
      allowed_headers    = var.cors_rule.allowed_headers
      allowed_methods    = var.cors_rule.allowed_methods
      allowed_origins    = var.cors_rule.allowed_origins
      exposed_headers    = var.cors_rule.exposed_headers
      max_age_in_seconds = var.cors_rule.max_age_in_seconds
    }
  }

  dynamic "virtual_network_rule" {
    for_each = var.virtual_network_rules

    content {
      id                                   = virtual_network_rule.value.subnet_id
      ignore_missing_vnet_service_endpoint = false
    }
  }

  dynamic "capabilities" {
    for_each = var.capabilities

    content {
      name = capabilities.value.name
    }
  }

  lifecycle {
    precondition {
      condition     = var.backup.type == local.continuous_backup_policy && var.multiple_write_locations_enabled ? false : true
      error_message = "Continuous backup mode and multiple write locations cannot be enabled together."
    }

    precondition {
      condition     = var.analytical_storage_enabled && var.partition_merge_enabled ? false : true
      error_message = "Analytical storage and partition merge cannot be enabled together."
    }

    precondition {
      condition     = contains(var.capabilities, "EnableServerless") && length(local.normalized_geo_locations) > 1 ? false : true
      error_message = "Serverless mode can only be enabled in a single region."
    }
  }


}

resource "time_sleep" "wait_180_seconds_for_destroy" {
  count            = length(var.diagnostic_settings) > 0 ? 1 : 0
  destroy_duration = "180s"

  triggers = {
    account_id = azurerm_cosmosdb_account.this.id
  }
}
