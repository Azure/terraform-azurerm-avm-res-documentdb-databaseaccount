output "cosmosdb_gremlin_connection_strings" {
  description = "The Gremlin connection strings for the CosmosDB Account."
  sensitive   = true
  value = {
    primary_gremlin_connection_string            = "${azurerm_cosmosdb_account.this.primary_sql_connection_string}ApiKind=Gremlin;"
    secondary_gremlin_connection_string          = "${azurerm_cosmosdb_account.this.secondary_sql_connection_string}ApiKind=Gremlin;"
    primary_readonly_gremlin_connection_string   = "${azurerm_cosmosdb_account.this.primary_readonly_sql_connection_string}ApiKind=Gremlin;"
    secondary_readonly_gremlin_connection_string = "${azurerm_cosmosdb_account.this.secondary_readonly_sql_connection_string}ApiKind=Gremlin;"
  }
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

output "gremlin_databases" {
  description = "A map of the Gremlin databases created, with the database name as the key and the database id and graphs as the value."
  value = { for db in azurerm_cosmosdb_gremlin_database.this : db.name =>
    {
      id = db.id

      graphs = {
        for graph in azurerm_cosmosdb_gremlin_graph.this :
        graph.name => graph.id
        if graph.database_name == db.name
      }
    }
  }
}

output "mongo_databases" {
  description = "A map of the MongoDB databases created, with the database name as the key and the database id and collections as the value."
  value = { for db in azurerm_cosmosdb_mongo_database.this : db.name =>
    {
      id = db.id

      collections = {
        for collection in azurerm_cosmosdb_mongo_collection.this :
        collection.name => collection.id
        if collection.database_name == db.name
      }
    }
  }
}

output "name" {
  description = "The name of the cosmos db account created."
  value       = azurerm_cosmosdb_account.this.name
}

output "resource_diagnostic_settings" {
  description = "A map of the diagnostic settings created, with the diagnostic setting name as the key and the diagnostic setting ID as the value."
  value       = { for diagnostic in azurerm_monitor_diagnostic_setting.this : diagnostic.name => diagnostic.id }
}

output "resource_id" {
  description = "The resource ID of the cosmos db account created."
  value       = azurerm_cosmosdb_account.this.id
}

output "resource_locks" {
  description = "A map of the management locks created, with the lock name as the key and the lock ID as the value."
  value       = { for locks in azurerm_management_lock.this : locks.name => locks.id }
}

output "resource_private_endpoints" {
  description = "A map of the management locks created, with the lock name as the key and the lock ID as the value."
  value       = { for endpoint in var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups : azurerm_private_endpoint.this_unmanaged_dns_zone_groups : endpoint.name => endpoint.id }
}

output "resource_private_endpoints_application_security_group_association" {
  description = "The IDs of the private endpoint application security group associations created."
  value       = [for association in azurerm_private_endpoint_application_security_group_association.this : association.id]
}

output "resource_role_assignments" {
  description = "A map of the role assignments created, with the assignment key as the map key and the assignment value as the map value."
  value       = { for role in azurerm_role_assignment.this : role.name => role.id }
}

output "sql_databases" {
  description = "A map of the SQL databases created, with the database name as the key and the database ID, containers, functions, stored_procedures and triggers as the value."
  value = { for db in azurerm_cosmosdb_sql_database.this : db.name =>
    {
      id = db.id

      containers = {
        for container in azurerm_cosmosdb_sql_container.this :
        container.name =>
        {
          id = container.id

          functions = {
            for func in azurerm_cosmosdb_sql_function.this :
            func.name => func.id
            if func.container_id == db.id
          }

          stored_procedures = {
            for stored in azurerm_cosmosdb_sql_stored_procedure.this :
            stored.name => stored.id
            if stored.database_name == db.name && stored.container_name == container.name
          }

          triggers = {
            for trigger in azurerm_cosmosdb_sql_trigger.this :
            trigger.name => trigger.id
            if trigger.container_id == container.id
          }
        }
        if container.database_name == db.name
      }
    }
  }
}

output "sql_dedicated_gateway" {
  description = "The IDs of the SQL dedicated gateways created."
  value       = [for gateway in azurerm_cosmosdb_sql_dedicated_gateway.this : gateway.id]
}

# Additional comprehensive outputs for the CosmosDB account resource

output "resource" {
  description = "The complete azurerm_cosmosdb_account resource."
  value       = azurerm_cosmosdb_account.this
  sensitive   = true
}

output "endpoint" {
  description = "The endpoint for the CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.endpoint
}

output "read_endpoints" {
  description = "A list of read endpoints available for this CosmosDB account."
  value       = azurerm_cosmosdb_account.this.read_endpoints
}

output "write_endpoints" {
  description = "A list of write endpoints available for this CosmosDB account."
  value       = azurerm_cosmosdb_account.this.write_endpoints
}

output "resource_group_name" {
  description = "The name of the resource group in which the CosmosDB Account is created."
  value       = azurerm_cosmosdb_account.this.resource_group_name
}

output "location" {
  description = "The location/region where the CosmosDB Account is created."
  value       = azurerm_cosmosdb_account.this.location
}

output "tags" {
  description = "The tags assigned to the CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.tags
}

output "offer_type" {
  description = "The offer type for the CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.offer_type
}

output "kind" {
  description = "The kind of the CosmosDB Account (GlobalDocumentDB, MongoDB, Parse)."
  value       = azurerm_cosmosdb_account.this.kind
}

output "consistency_policy" {
  description = "The consistency policy configuration for the CosmosDB Account."
  value = {
    consistency_level       = azurerm_cosmosdb_account.this.consistency_policy[0].consistency_level
    max_interval_in_seconds = azurerm_cosmosdb_account.this.consistency_policy[0].max_interval_in_seconds
    max_staleness_prefix    = azurerm_cosmosdb_account.this.consistency_policy[0].max_staleness_prefix
  }
}

output "geo_location" {
  description = "The geo-location configuration for the CosmosDB Account."
  value = [
    for location in azurerm_cosmosdb_account.this.geo_location : {
      id                = location.id
      location          = location.location
      failover_priority = location.failover_priority
      zone_redundant    = location.zone_redundant
    }
  ]
}

output "capabilities" {
  description = "The capabilities enabled for the CosmosDB Account."
  value = [
    for capability in azurerm_cosmosdb_account.this.capabilities : {
      name = capability.name
    }
  ]
}

output "virtual_network_rule" {
  description = "The virtual network rules configured for the CosmosDB Account."
  value = [
    for rule in azurerm_cosmosdb_account.this.virtual_network_rule : {
      id                                   = rule.id
      ignore_missing_vnet_service_endpoint = rule.ignore_missing_vnet_service_endpoint
    }
  ]
}

output "analytical_storage" {
  description = "The analytical storage configuration for the CosmosDB Account."
  value = length(azurerm_cosmosdb_account.this.analytical_storage) > 0 ? {
    schema_type = azurerm_cosmosdb_account.this.analytical_storage[0].schema_type
  } : null
}

output "backup" {
  description = "The backup configuration for the CosmosDB Account."
  value = {
    type                = azurerm_cosmosdb_account.this.backup[0].type
    interval_in_minutes = azurerm_cosmosdb_account.this.backup[0].interval_in_minutes
    retention_in_hours  = azurerm_cosmosdb_account.this.backup[0].retention_in_hours
    storage_redundancy  = azurerm_cosmosdb_account.this.backup[0].storage_redundancy
    tier                = azurerm_cosmosdb_account.this.backup[0].tier
  }
}

output "capacity" {
  description = "The capacity configuration for the CosmosDB Account."
  value = {
    total_throughput_limit = azurerm_cosmosdb_account.this.capacity[0].total_throughput_limit
  }
}

output "cors_rule" {
  description = "The CORS rule configuration for the CosmosDB Account."
  value = length(azurerm_cosmosdb_account.this.cors_rule) > 0 ? {
    allowed_headers    = azurerm_cosmosdb_account.this.cors_rule[0].allowed_headers
    allowed_methods    = azurerm_cosmosdb_account.this.cors_rule[0].allowed_methods
    allowed_origins    = azurerm_cosmosdb_account.this.cors_rule[0].allowed_origins
    exposed_headers    = azurerm_cosmosdb_account.this.cors_rule[0].exposed_headers
    max_age_in_seconds = azurerm_cosmosdb_account.this.cors_rule[0].max_age_in_seconds
  } : null
}

output "identity" {
  description = "The managed identity configuration for the CosmosDB Account."
  value = length(azurerm_cosmosdb_account.this.identity) > 0 ? {
    type         = azurerm_cosmosdb_account.this.identity[0].type
    identity_ids = azurerm_cosmosdb_account.this.identity[0].identity_ids
    principal_id = azurerm_cosmosdb_account.this.identity[0].principal_id
    tenant_id    = azurerm_cosmosdb_account.this.identity[0].tenant_id
  } : null
}

output "access_key_metadata_writes_enabled" {
  description = "Whether access key metadata writes are enabled for the CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.access_key_metadata_writes_enabled
}

output "analytical_storage_enabled" {
  description = "Whether analytical storage is enabled for the CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.analytical_storage_enabled
}

output "automatic_failover_enabled" {
  description = "Whether automatic failover is enabled for the CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.automatic_failover_enabled
}

output "free_tier_enabled" {
  description = "Whether the free tier is enabled for the CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.free_tier_enabled
}

output "ip_range_filter" {
  description = "The IP range filter for the CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.ip_range_filter
}

output "is_virtual_network_filter_enabled" {
  description = "Whether virtual network filtering is enabled for the CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.is_virtual_network_filter_enabled
}

output "key_vault_key_id" {
  description = "The Key Vault key ID used for encryption."
  value       = azurerm_cosmosdb_account.this.key_vault_key_id
}

output "local_authentication_disabled" {
  description = "Whether local authentication is disabled for the CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.local_authentication_disabled
}

output "minimal_tls_version" {
  description = "The minimal TLS version for the CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.minimal_tls_version
}

output "mongo_server_version" {
  description = "The MongoDB server version for the CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.mongo_server_version
}

output "multiple_write_locations_enabled" {
  description = "Whether multiple write locations are enabled for the CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.multiple_write_locations_enabled
}

output "network_acl_bypass_for_azure_services" {
  description = "Whether network ACL bypass is enabled for Azure services."
  value       = azurerm_cosmosdb_account.this.network_acl_bypass_for_azure_services
}

output "network_acl_bypass_ids" {
  description = "The list of resource IDs that are allowed to bypass network ACLs."
  value       = azurerm_cosmosdb_account.this.network_acl_bypass_ids
}

output "partition_merge_enabled" {
  description = "Whether partition merge is enabled for the CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.partition_merge_enabled
}

output "public_network_access_enabled" {
  description = "Whether public network access is enabled for the CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.public_network_access_enabled
}

output "default_identity_type" {
  description = "The default identity type for the CosmosDB Account."
  value       = azurerm_cosmosdb_account.this.default_identity_type
}
