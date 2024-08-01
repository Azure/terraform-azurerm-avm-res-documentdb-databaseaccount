resource "azurerm_cosmosdb_account" "this" {
  location                              = var.location
  name                                  = var.name
  offer_type                            = "Standard"
  resource_group_name                   = var.resource_group_name
  access_key_metadata_writes_enabled    = var.access_key_metadata_writes_enabled
  analytical_storage_enabled            = var.analytical_storage_enabled
  automatic_failover_enabled            = var.automatic_failover_enabled
  default_identity_type                 = local.normalized_cmk_default_identity_type
  free_tier_enabled                     = var.free_tier_enabled
  ip_range_filter                       = local.normalized_ip_range_filter
  is_virtual_network_filter_enabled     = length(var.virtual_network_rules) > 0 ? true : false
  key_vault_key_id                      = local.normalized_cmk_key_url
  kind                                  = length(var.mongo_databases) > 0 ? "MongoDB" : "GlobalDocumentDB"
  local_authentication_disabled         = var.local_authentication_disabled
  minimal_tls_version                   = var.minimal_tls_version
  mongo_server_version                  = length(var.mongo_databases) > 0 ? var.mongo_server_version : null
  multiple_write_locations_enabled      = var.backup.type == local.periodic_backup_policy ? var.multiple_write_locations_enabled : false
  network_acl_bypass_for_azure_services = var.network_acl_bypass_for_azure_services
  network_acl_bypass_ids                = var.network_acl_bypass_ids
  partition_merge_enabled               = var.partition_merge_enabled
  public_network_access_enabled         = var.public_network_access_enabled
  tags                                  = var.tags

  consistency_policy {
    consistency_level       = var.consistency_policy.consistency_level
    max_interval_in_seconds = var.consistency_policy.consistency_level == local.consistent_prefix_consistency ? var.consistency_policy.max_interval_in_seconds : null
    max_staleness_prefix    = var.consistency_policy.consistency_level == local.consistent_prefix_consistency ? var.consistency_policy.max_staleness_prefix : null
  }
  dynamic "geo_location" {
    for_each = local.normalized_geo_locations

    content {
      failover_priority = geo_location.value.failover_priority
      location          = geo_location.value.location
      zone_redundant    = geo_location.value.zone_redundant
    }
  }
  dynamic "analytical_storage" {
    for_each = var.analytical_storage_config != null ? [1] : []

    content {
      schema_type = var.analytical_storage_config.schema_type
    }
  }
  backup {
    type                = var.backup.type
    interval_in_minutes = var.backup.type == local.periodic_backup_policy ? var.backup.interval_in_minutes : null
    retention_in_hours  = var.backup.type == local.periodic_backup_policy ? var.backup.retention_in_hours : null
    storage_redundancy  = var.backup.type == local.periodic_backup_policy ? var.backup.storage_redundancy : null
    tier                = var.backup.type == local.continuous_backup_policy ? var.backup.tier : null
  }
  dynamic "capabilities" {
    for_each = var.capabilities

    content {
      name = capabilities.value.name
    }
  }
  capacity {
    total_throughput_limit = var.capacity.total_throughput_limit
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
  dynamic "identity" {
    for_each = local.managed_identities.system_assigned_user_assigned

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }
  dynamic "virtual_network_rule" {
    for_each = var.virtual_network_rules

    content {
      id                                   = virtual_network_rule.value.subnet_id
      ignore_missing_vnet_service_endpoint = false
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
    precondition {
      condition     = !(length(var.sql_databases) > 0 && length(var.mongo_databases) > 0)
      error_message = "You can only create either SQL or MongoDB databases, not both."
    }
  }
}

resource "time_sleep" "wait_180_seconds_for_destroy" {
  count = length(var.diagnostic_settings) > 0 ? 1 : 0

  destroy_duration = "180s"
  triggers = {
    account_id = azurerm_cosmosdb_account.this.id
  }
}
