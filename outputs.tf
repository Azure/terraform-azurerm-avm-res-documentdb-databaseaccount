output "access_key_metadata_writes_enabled" {
  description = "Whether access key metadata writes are enabled for the CosmosDB Account."
  value       = var.access_key_metadata_writes_enabled
}

output "analytical_storage" {
  description = "The analytical storage configuration for the CosmosDB Account."
  value       = local.output_analytical_storage
}

output "analytical_storage_enabled" {
  description = "Whether analytical storage is enabled for the CosmosDB Account."
  value       = var.analytical_storage_enabled
}

output "automatic_failover_enabled" {
  description = "Whether automatic failover is enabled for the CosmosDB Account."
  value       = var.automatic_failover_enabled
}

output "backup" {
  description = "The backup configuration for the CosmosDB Account."
  value       = local.output_backup
}

output "capabilities" {
  description = "The capabilities enabled for the CosmosDB Account."
  value       = local.output_capabilities
}

output "capacity" {
  description = "The capacity configuration for the CosmosDB Account."
  value       = local.output_capacity
}

output "consistency_policy" {
  description = "The consistency policy configuration for the CosmosDB Account."
  value       = local.output_consistency_policy
}

output "cors_rule" {
  description = "The CORS rule configuration for the CosmosDB Account."
  value       = local.output_cors_rule
}

output "cosmosdb_keys" {
  description = "The keys for the CosmosDB Account."
  sensitive   = true
  value       = local.output_keys
}

output "cosmosdb_mongodb_connection_strings" {
  description = "The MongoDB connection strings for the CosmosDB Account."
  sensitive   = true
  value = {
    primary_mongodb_connection_string            = local.output_connection_strings.primary_mongodb_connection_string
    secondary_mongodb_connection_string          = local.output_connection_strings.secondary_mongodb_connection_string
    primary_readonly_mongodb_connection_string   = local.output_connection_strings.primary_readonly_mongodb_connection_string
    secondary_readonly_mongodb_connection_string = local.output_connection_strings.secondary_readonly_mongodb_connection_string
  }
}

output "cosmosdb_sql_connection_strings" {
  description = "The SQL connection strings for the CosmosDB Account."
  sensitive   = true
  value = {
    primary_sql_connection_string            = local.output_connection_strings.primary_sql_connection_string
    secondary_sql_connection_string          = local.output_connection_strings.secondary_sql_connection_string
    primary_readonly_sql_connection_string   = local.output_connection_strings.primary_readonly_sql_connection_string
    secondary_readonly_sql_connection_string = local.output_connection_strings.secondary_readonly_sql_connection_string
  }
}

output "default_identity_type" {
  description = "The default identity type for the CosmosDB Account."
  value       = local.account_properties.defaultIdentity
}

output "endpoint" {
  description = "The endpoint for the CosmosDB Account."
  value       = local.output_endpoint
}

output "free_tier_enabled" {
  description = "Whether the free tier is enabled for the CosmosDB Account."
  value       = var.free_tier_enabled
}

output "geo_location" {
  description = "The geo-location configuration for the CosmosDB Account."
  value       = local.output_geo_location
}

output "identity" {
  description = "The managed identity configuration for the CosmosDB Account."
  value       = local.output_identity
}

output "ip_range_filter" {
  description = "The IP range filter for the CosmosDB Account."
  value       = toset(local.trimmed_ip_range_filter)
}

output "is_virtual_network_filter_enabled" {
  description = "Whether virtual network filtering is enabled for the CosmosDB Account."
  value       = local.account_properties.isVirtualNetworkFilterEnabled
}

output "key_vault_key_id" {
  description = "The Key Vault key ID used for encryption."
  value       = local.normalized_cmk_key_url
}

output "kind" {
  description = "The kind of the CosmosDB Account (GlobalDocumentDB, MongoDB, Parse)."
  value       = local.kind
}

output "local_authentication_disabled" {
  description = "Whether local authentication is disabled for the CosmosDB Account."
  value       = local.local_authentication_disabled
}

output "location" {
  description = "The location/region where the CosmosDB Account is created."
  value       = local.output_location
}

output "minimal_tls_version" {
  description = "The minimal TLS version for the CosmosDB Account."
  value       = var.minimal_tls_version
}

output "mongo_databases" {
  description = "A map of the MongoDB databases created, with the database name as the key and the database id and collections as the value."
  value = {
    for database_key, database in azapi_resource.mongo_databases : database.name => {
      id = database.id

      collections = {
        for collection_key, collection in azapi_resource.mongo_collections :
        collection.name => collection.id
        if local.mongodb_collections[collection_key].db_name == database_key
      }
    }
  }
}

output "mongo_server_version" {
  description = "The MongoDB server version for the CosmosDB Account."
  value       = local.output_mongo_server_version
}

output "multiple_write_locations_enabled" {
  description = "Whether multiple write locations are enabled for the CosmosDB Account."
  value       = local.multiple_write_locations_enabled
}

output "name" {
  description = "The name of the cosmos db account created."
  value       = azapi_resource.this.name
}

output "network_acl_bypass_for_azure_services" {
  description = "Whether network ACL bypass is enabled for Azure services."
  value       = var.network_acl_bypass_for_azure_services
}

output "network_acl_bypass_ids" {
  description = "The list of resource IDs that are allowed to bypass network ACLs."
  value       = local.account_properties.networkAclBypassResourceIds
}

output "offer_type" {
  description = "The offer type for the CosmosDB Account."
  value       = local.account_properties.databaseAccountOfferType
}

output "partition_merge_enabled" {
  description = "Whether partition merge is enabled for the CosmosDB Account."
  value       = var.partition_merge_enabled
}

output "public_network_access_enabled" {
  description = "Whether public network access is enabled for the CosmosDB Account."
  value       = var.public_network_access_enabled
}

output "read_endpoints" {
  description = "A list of read endpoints available for this CosmosDB account."
  value       = azapi_resource.this.output.read_endpoints
}

output "resource" {
  description = "The CosmosDB account, with the attributes of the `azurerm_cosmosdb_account` resource that earlier versions of this module returned."
  sensitive   = true
  value = merge(local.output_connection_strings, local.output_keys, {
    access_key_metadata_writes_enabled    = var.access_key_metadata_writes_enabled
    analytical_storage                    = local.output_analytical_storage == null ? [] : [local.output_analytical_storage]
    analytical_storage_enabled            = var.analytical_storage_enabled
    automatic_failover_enabled            = var.automatic_failover_enabled
    backup                                = [local.output_backup]
    burst_capacity_enabled                = var.burst_capacity_enabled
    capabilities                          = local.output_capabilities
    capacity                              = [local.output_capacity]
    consistency_policy                    = [local.output_consistency_policy]
    cors_rule                             = local.output_cors_rule == null ? [] : [local.output_cors_rule]
    default_identity_type                 = local.account_properties.defaultIdentity
    endpoint                              = local.output_endpoint
    free_tier_enabled                     = var.free_tier_enabled
    geo_location                          = local.output_geo_location
    id                                    = azapi_resource.this.id
    identity                              = local.output_identity == null ? [] : [local.output_identity]
    ip_range_filter                       = toset(local.trimmed_ip_range_filter)
    is_virtual_network_filter_enabled     = local.account_properties.isVirtualNetworkFilterEnabled
    key_vault_key_id                      = local.normalized_cmk_key_url
    kind                                  = local.kind
    local_authentication_disabled         = local.local_authentication_disabled
    location                              = local.output_location
    minimal_tls_version                   = var.minimal_tls_version
    mongo_server_version                  = local.output_mongo_server_version
    multiple_write_locations_enabled      = local.multiple_write_locations_enabled
    name                                  = azapi_resource.this.name
    network_acl_bypass_for_azure_services = var.network_acl_bypass_for_azure_services
    network_acl_bypass_ids                = local.account_properties.networkAclBypassResourceIds
    offer_type                            = local.account_properties.databaseAccountOfferType
    partition_merge_enabled               = var.partition_merge_enabled
    public_network_access_enabled         = var.public_network_access_enabled
    read_endpoints                        = azapi_resource.this.output.read_endpoints
    resource_group_name                   = local.resource_group_name
    tags                                  = var.tags
    virtual_network_rule                  = local.output_virtual_network_rule
    write_endpoints                       = azapi_resource.this.output.write_endpoints
  })
}

output "resource_diagnostic_settings" {
  description = "A map of the diagnostic settings created, with the diagnostic setting name as the key and the diagnostic setting ID as the value."
  value       = { for diagnostic in azapi_resource.diagnostic_settings : diagnostic.name => diagnostic.id }
}

output "resource_group_name" {
  description = "The name of the resource group in which the CosmosDB Account is created."
  value       = local.resource_group_name
}

output "resource_id" {
  description = "The resource ID of the cosmos db account created."
  value       = azapi_resource.this.id
}

output "resource_locks" {
  description = "A map of the management locks created, with the lock name as the key and the lock ID as the value."
  value       = { for lock in azapi_resource.locks : lock.name => lock.id }
}

output "resource_private_endpoints" {
  description = "A map of the private endpoints created, with the private endpoint name as the key and the private endpoint ID as the value."
  value       = { for endpoint in var.private_endpoints_manage_dns_zone_group ? azapi_resource.private_endpoints : azapi_resource.private_endpoints_unmanaged : endpoint.name => endpoint.id }
}

output "resource_private_endpoints_application_security_group_association" {
  description = "The private endpoint application security group associations, in the `<private endpoint ID>|<application security group ID>` form of the association IDs that earlier versions of this module returned."
  value       = [for association in local.private_endpoint_application_security_group_associations : "${local.private_endpoint_ids[association.pe_key]}|${association.asg_resource_id}"]
}

output "resource_role_assignments" {
  description = "A map of the role assignments created, with the assignment name as the map key and the assignment ID as the map value."
  value       = { for role in azapi_resource.role_assignments : role.name => role.id }
}

output "sql_databases" {
  description = "A map of the SQL databases created, with the database name as the key and the database ID, containers, functions, stored_procedures and triggers as the value."
  value = {
    for database_key, database in azapi_resource.sql_databases : database.name => {
      id = database.id

      containers = {
        for container_key, container in azapi_resource.sql_containers :
        container.name => {
          id = container.id

          functions = {
            for function_key, function in azapi_resource.sql_functions :
            function.name => function.id
            if local.sql_container_functions[function_key].container_key == container_key
          }

          stored_procedures = {
            for procedure_key, procedure in azapi_resource.sql_stored_procedures :
            procedure.name => procedure.id
            if local.sql_container_stored_procedures[procedure_key].container_key == container_key
          }

          triggers = {
            for trigger_key, trigger in azapi_resource.sql_triggers :
            trigger.name => trigger.id
            if local.sql_container_triggers[trigger_key].container_key == container_key
          }
        }
        if local.sql_containers[container_key].db_name == database_key
      }
    }
  }
}

output "sql_dedicated_gateway" {
  description = "The IDs of the SQL dedicated gateways created."
  value       = [for gateway in azapi_resource.sql_dedicated_gateway : gateway.id]
}

output "tags" {
  description = "The tags assigned to the CosmosDB Account."
  value       = var.tags
}

output "virtual_network_rule" {
  description = "The virtual network rules configured for the CosmosDB Account."
  value       = local.output_virtual_network_rule
}

output "write_endpoints" {
  description = "A list of write endpoints available for this CosmosDB account."
  value       = azapi_resource.this.output.write_endpoints
}
