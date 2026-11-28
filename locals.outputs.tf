locals {
  # The values that earlier versions read from the `azurerm_cosmosdb_account` resource, in the same shapes, for the
  # outputs.
  # Azure sets a schema type when none is configured, which earlier versions returned.
  output_analytical_storage = var.analytical_storage_config == null && try(azapi_resource.this.output.analytical_storage_schema_type, null) == null ? null : {
    schema_type = var.analytical_storage_config != null ? var.analytical_storage_config.schema_type : azapi_resource.this.output.analytical_storage_schema_type
  }
  # Settings of the other backup type are empty, as before.
  output_backup = {
    interval_in_minutes = var.backup.type == local.periodic_backup_policy ? var.backup.interval_in_minutes : 0
    retention_in_hours  = var.backup.type == local.periodic_backup_policy ? var.backup.retention_in_hours : 0
    storage_redundancy  = var.backup.type == local.periodic_backup_policy ? var.backup.storage_redundancy : ""
    tier                = var.backup.type == local.continuous_backup_policy ? var.backup.tier : ""
    type                = var.backup.type
  }
  output_capabilities = [for name in local.capability_names : { name = name }]
  output_capacity = {
    total_throughput_limit = var.capacity.total_throughput_limit
  }
  # As before, a connection string that the account does not have is null.
  output_connection_strings = {
    primary_mongodb_connection_string            = lookup(local.connection_strings, "Primary MongoDB Connection String", null)
    primary_readonly_mongodb_connection_string   = lookup(local.connection_strings, "Primary Read-Only MongoDB Connection String", null)
    primary_readonly_sql_connection_string       = lookup(local.connection_strings, "Primary Read-Only SQL Connection String", null)
    primary_sql_connection_string                = lookup(local.connection_strings, "Primary SQL Connection String", null)
    secondary_mongodb_connection_string          = lookup(local.connection_strings, "Secondary MongoDB Connection String", null)
    secondary_readonly_mongodb_connection_string = lookup(local.connection_strings, "Secondary Read-Only MongoDB Connection String", null)
    secondary_readonly_sql_connection_string     = lookup(local.connection_strings, "Secondary Read-Only SQL Connection String", null)
    secondary_sql_connection_string              = lookup(local.connection_strings, "Secondary SQL Connection String", null)
  }
  # As before, the staleness settings are only returned for bounded staleness.
  output_consistency_policy = {
    consistency_level       = var.consistency_policy.consistency_level
    max_interval_in_seconds = var.consistency_policy.consistency_level == local.bounded_staleness_consistency ? var.consistency_policy.max_interval_in_seconds : null
    max_staleness_prefix    = var.consistency_policy.consistency_level == local.bounded_staleness_consistency ? var.consistency_policy.max_staleness_prefix : null
  }
  output_cors_rule = var.cors_rule == null ? null : {
    allowed_headers    = tolist(var.cors_rule.allowed_headers)
    allowed_methods    = tolist(var.cors_rule.allowed_methods)
    allowed_origins    = tolist(var.cors_rule.allowed_origins)
    exposed_headers    = tolist(var.cors_rule.exposed_headers)
    max_age_in_seconds = var.cors_rule.max_age_in_seconds
  }
  # The document endpoint does not change, so the endpoint of an existing account is read from Azure. It stays
  # known while the account has changes pending, as it did with the AzureRM provider.
  output_endpoint = local.account_exists ? data.azapi_resource.account.output.document_endpoint : azapi_resource.this.output.document_endpoint
  output_geo_location = [
    for location in local.normalized_geo_locations : {
      failover_priority = location.failover_priority
      id                = "${var.name}-${lower(replace(location.location, " ", ""))}"
      location          = lower(replace(location.location, " ", ""))
      zone_redundant    = location.zone_redundant
    }
  ]
  output_identity = length(azapi_resource.this.identity) == 0 ? null : {
    identity_ids = azapi_resource.this.identity[0].identity_ids
    principal_id = azapi_resource.this.identity[0].principal_id
    tenant_id    = azapi_resource.this.identity[0].tenant_id
    type         = azapi_resource.this.identity[0].type
  }
  output_keys = {
    primary_key            = try(local.secrets.keys.primaryMasterKey, "")
    primary_readonly_key   = try(local.secrets.readonly_keys.primaryReadonlyMasterKey, "")
    secondary_key          = try(local.secrets.keys.secondaryMasterKey, "")
    secondary_readonly_key = try(local.secrets.readonly_keys.secondaryReadonlyMasterKey, "")
  }
  output_location             = lower(replace(var.location, " ", ""))
  output_mongo_server_version = local.kind == "MongoDB" ? var.mongo_server_version : null
  output_virtual_network_rule = [
    for rule in var.virtual_network_rules : {
      id                                   = rule.subnet_id
      ignore_missing_vnet_service_endpoint = false
    }
  ]
}
