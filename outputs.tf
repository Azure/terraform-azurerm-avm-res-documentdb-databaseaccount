# ============================
# PRIMARY RESOURCE OUTPUTS
# ============================

output "resource" {
  description = "The full resource object of the CosmosDB Account."
  value       = azurerm_cosmosdb_account.this
}

output "cosmosdb_keys" {
  description = "The keys for the CosmosDB Account."
  sensitive   = true
  value = {
    primary_key            = azurerm_cosmosdb_account.this.primary_key
    secondary_key          = azurerm_cosmosdb_account.this.secondary_key
    primary_readonly_key   = azurerm_cosmosdb_account.this.primary_readonly_key
    secondary_readonly_key = azurerm_cosmosdb_account.this.secondary_readonly_key
  }
}

output "endpoint" {
  description = "The endpoint used to connect to the CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.endpoint
}

output "read_endpoints" {
  description = "A list of read endpoints available for this CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.read_endpoints
}

output "write_endpoints" {
  description = "A list of write endpoints available for this CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.write_endpoints
}

output "identity" {
  description = "The managed identity configuration of the CosmosDB Account."
  value = azurerm_cosmosdb_account.this.identity != null ? {
    type         = azurerm_cosmosdb_account.this.identity[0].type
    identity_ids = azurerm_cosmosdb_account.this.identity[0].identity_ids
    principal_id = azurerm_cosmosdb_account.this.identity[0].principal_id
    tenant_id    = azurerm_cosmosdb_account.this.identity[0].tenant_id
  } : null
}

# ============================
# CONNECTION STRING OUTPUTS
# ============================

output "cosmosdb_mongodb_connection_strings" {
  description = "The MongoDB connection strings for the CosmosDB Account."
  sensitive   = true
  value = {
    primary_mongodb_connection_string            = azurerm_cosmosdb_account.this.primary_mongodb_connection_string
    secondary_mongodb_connection_string          = azurerm_cosmosdb_account.this.secondary_mongodb_connection_string
    primary_readonly_mongodb_connection_string   = azurerm_cosmosdb_account.this.primary_readonly_mongodb_connection_string
    secondary_readonly_mongodb_connection_string = azurerm_cosmosdb_account.this.secondary_readonly_mongodb_connection_string
  }
}

output "cosmosdb_sql_connection_strings" {
  description = "The SQL connection strings for the CosmosDB Account."
  sensitive   = true
  value = {
    primary_sql_connection_string            = azurerm_cosmosdb_account.this.primary_sql_connection_string
    secondary_sql_connection_string          = azurerm_cosmosdb_account.this.secondary_sql_connection_string
    primary_readonly_sql_connection_string   = azurerm_cosmosdb_account.this.primary_readonly_sql_connection_string
    secondary_readonly_sql_connection_string = azurerm_cosmosdb_account.this.secondary_readonly_sql_connection_string
  }
}

# ============================
# DATABASE API OUTPUTS
# ============================

output "mongo_databases" {
  description = "A map of the MongoDB databases created, with the database name as the key and the database id and collections as the value."
  value = { for db in azurerm_cosmosdb_mongo_database.this : db.name =>
    {
      id                  = db.id
      name                = db.name
      account_name        = db.account_name
      resource_group_name = db.resource_group_name
      throughput          = db.throughput
      autoscale_settings  = db.autoscale_settings

      collections = {
        for collection in azurerm_cosmosdb_mongo_collection.this :
        collection.name => {
          id                  = collection.id
          name                = collection.name
          account_name        = collection.account_name
          database_name       = collection.database_name
          resource_group_name = collection.resource_group_name
          default_ttl_seconds = collection.default_ttl_seconds
          shard_key           = collection.shard_key
          throughput          = collection.throughput
          autoscale_settings  = collection.autoscale_settings
          index               = collection.index
        }
        if collection.database_name == db.name
      }
    }
  }
}

output "sql_dedicated_gateway" {
  description = "The details of the SQL dedicated gateways created."
  value = length(azurerm_cosmosdb_sql_dedicated_gateway.this) > 0 ? {
    for gateway in azurerm_cosmosdb_sql_dedicated_gateway.this :
    "gateway-${gateway.instance_size}-${gateway.instance_count}" => {
      id                  = gateway.id
      cosmosdb_account_id = gateway.cosmosdb_account_id
      instance_count      = gateway.instance_count
      instance_size       = gateway.instance_size
    }
  } : {}
}

# ============================
# INFRASTRUCTURE OUTPUTS
# ============================

output "resource_diagnostic_settings" {
  description = "A map of the diagnostic settings created, with the diagnostic setting name as the key and the complete diagnostic setting details as the value."
  value = { for diagnostic in azurerm_monitor_diagnostic_setting.this : diagnostic.name => {
    id                             = diagnostic.id
    name                           = diagnostic.name
    target_resource_id             = diagnostic.target_resource_id
    eventhub_authorization_rule_id = diagnostic.eventhub_authorization_rule_id
    eventhub_name                  = diagnostic.eventhub_name
    log_analytics_destination_type = diagnostic.log_analytics_destination_type
    log_analytics_workspace_id     = diagnostic.log_analytics_workspace_id
    partner_solution_id            = diagnostic.partner_solution_id
    storage_account_id             = diagnostic.storage_account_id
    enabled_log                    = diagnostic.enabled_log
    metric                         = diagnostic.metric
  } }
}

output "resource_locks" {
  description = "A map of the management locks created, with the lock name as the key and the complete lock details as the value."
  value = { for locks in azurerm_management_lock.this : locks.name => {
    id         = locks.id
    name       = locks.name
    lock_level = locks.lock_level
    scope      = locks.scope
    notes      = locks.notes
  } }
}

output "resource_private_endpoints" {
  description = "A map of the private endpoints created, with the endpoint name as the key and the complete endpoint details as the value."
  value = { for endpoint in var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups : azurerm_private_endpoint.this_unmanaged_dns_zone_groups : endpoint.name => {
    id                            = endpoint.id
    name                          = endpoint.name
    location                      = endpoint.location
    resource_group_name           = endpoint.resource_group_name
    subnet_id                     = endpoint.subnet_id
    custom_network_interface_name = endpoint.custom_network_interface_name
    private_service_connection    = endpoint.private_service_connection
    ip_configuration              = endpoint.ip_configuration
    private_dns_zone_group        = endpoint.private_dns_zone_group
    network_interface             = endpoint.network_interface
    private_dns_zone_configs      = endpoint.private_dns_zone_configs
    tags                          = endpoint.tags
  } }
}

output "resource_private_endpoints_application_security_group_association" {
  description = "A map of the private endpoint application security group associations created."
  value = { for association in azurerm_private_endpoint_application_security_group_association.this : association.id => {
    id                            = association.id
    private_endpoint_id           = association.private_endpoint_id
    application_security_group_id = association.application_security_group_id
  } }
}

output "resource_role_assignments" {
  description = "A map of the role assignments created, with the assignment name as the key and the complete role assignment details as the value."
  value = { for role in azurerm_role_assignment.this : role.name => {
    id                                     = role.id
    name                                   = role.name
    scope                                  = role.scope
    principal_id                           = role.principal_id
    role_definition_id                     = role.role_definition_id
    role_definition_name                   = role.role_definition_name
    delegated_managed_identity_resource_id = role.delegated_managed_identity_resource_id
    skip_service_principal_aad_check       = role.skip_service_principal_aad_check
    principal_type                         = role.principal_type
  } }
}

# ============================
# TELEMETRY OUTPUTS
# ============================

output "resource_telemetry" {
  description = "Telemetry resource details for monitoring and tracking."
  value = var.enable_telemetry ? {
    telemetry_id = length(modtm_telemetry.telemetry) > 0 ? modtm_telemetry.telemetry[0].id : null
    random_uuid  = length(random_uuid.telemetry) > 0 ? random_uuid.telemetry[0].result : null
    client_config = length(data.azurerm_client_config.telemetry) > 0 ? {
      subscription_id = data.azurerm_client_config.telemetry[0].subscription_id
      tenant_id       = data.azurerm_client_config.telemetry[0].tenant_id
    } : null
    module_source = length(data.modtm_module_source.telemetry) > 0 ? {
      module_source  = data.modtm_module_source.telemetry[0].module_source
      module_version = data.modtm_module_source.telemetry[0].module_version
    } : null
  } : null
}

# ============================
# GEOGRAPHIC DISTRIBUTION OUTPUTS
# ============================

output "geo_locations" {
  description = "The geographic locations where the CosmosDB Account is replicated."
  value = azurerm_cosmosdb_account.this.geo_location != null ? [
    for geo in azurerm_cosmosdb_account.this.geo_location : {
      location          = geo.location
      failover_priority = geo.failover_priority
      zone_redundant    = geo.zone_redundant
      id                = geo.id
    }
  ] : []
}

# ============================
# COMPLETE RESOURCE COLLECTIONS
# ============================

output "all_resources" {
  description = "A complete collection of all resources created by this module, organized by resource type."
  value = {
    cosmosdb_account = {
      main = {
        id                 = azurerm_cosmosdb_account.this.id
        name               = azurerm_cosmosdb_account.this.name
        endpoint           = azurerm_cosmosdb_account.this.endpoint
        kind               = azurerm_cosmosdb_account.this.kind
        offer_type         = azurerm_cosmosdb_account.this.offer_type
        consistency_policy = azurerm_cosmosdb_account.this.consistency_policy
        geo_location       = azurerm_cosmosdb_account.this.geo_location
        capabilities       = azurerm_cosmosdb_account.this.capabilities
      }
    }

    sql_databases = { for db in azurerm_cosmosdb_sql_database.this : db.name => {
      id                 = db.id
      name               = db.name
      throughput         = db.throughput
      autoscale_settings = db.autoscale_settings
    } }

    sql_containers = { for container in azurerm_cosmosdb_sql_container.this : container.name => {
      id                    = container.id
      name                  = container.name
      database_name         = container.database_name
      partition_key_paths   = container.partition_key_paths
      partition_key_version = container.partition_key_version
      throughput            = container.throughput
      autoscale_settings    = container.autoscale_settings
    } }

    sql_functions = { for func in azurerm_cosmosdb_sql_function.this : func.name => {
      id           = func.id
      name         = func.name
      container_id = func.container_id
    } }

    sql_stored_procedures = { for stored in azurerm_cosmosdb_sql_stored_procedure.this : stored.name => {
      id             = stored.id
      name           = stored.name
      database_name  = stored.database_name
      container_name = stored.container_name
    } }

    sql_triggers = { for trigger in azurerm_cosmosdb_sql_trigger.this : trigger.name => {
      id           = trigger.id
      name         = trigger.name
      container_id = trigger.container_id
      operation    = trigger.operation
      type         = trigger.type
    } }

    sql_dedicated_gateways = { for gateway in azurerm_cosmosdb_sql_dedicated_gateway.this : "gateway-${gateway.instance_size}-${gateway.instance_count}" => {
      id                  = gateway.id
      instance_count      = gateway.instance_count
      instance_size       = gateway.instance_size
      cosmosdb_account_id = gateway.cosmosdb_account_id
    } }

    mongo_databases = { for db in azurerm_cosmosdb_mongo_database.this : db.name => {
      id                 = db.id
      name               = db.name
      throughput         = db.throughput
      autoscale_settings = db.autoscale_settings
    } }

    mongo_collections = { for collection in azurerm_cosmosdb_mongo_collection.this : collection.name => {
      id                  = collection.id
      name                = collection.name
      database_name       = collection.database_name
      default_ttl_seconds = collection.default_ttl_seconds
      shard_key           = collection.shard_key
      throughput          = collection.throughput
      autoscale_settings  = collection.autoscale_settings
    } }

    diagnostic_settings = { for diagnostic in azurerm_monitor_diagnostic_setting.this : diagnostic.name => {
      id                 = diagnostic.id
      name               = diagnostic.name
      target_resource_id = diagnostic.target_resource_id
    } }

    management_locks = { for lock in azurerm_management_lock.this : lock.name => {
      id         = lock.id
      name       = lock.name
      lock_level = lock.lock_level
      scope      = lock.scope
    } }

    private_endpoints = { for endpoint in var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups : azurerm_private_endpoint.this_unmanaged_dns_zone_groups : endpoint.name => {
      id                  = endpoint.id
      name                = endpoint.name
      location            = endpoint.location
      resource_group_name = endpoint.resource_group_name
      subnet_id           = endpoint.subnet_id
    } }

    role_assignments = { for role in azurerm_role_assignment.this : role.name => {
      id                   = role.id
      name                 = role.name
      scope                = role.scope
      principal_id         = role.principal_id
      role_definition_name = role.role_definition_name
    } }
  }
}

# ============================
# BASIC RESOURCE IDENTIFIERS
# ============================

output "name" {
  description = "The name of the cosmos db account created."
  value       = azurerm_cosmosdb_account.this.name
}

output "resource_id" {
  description = "The resource ID of the cosmos db account created."
  value       = azurerm_cosmosdb_account.this.id
}
