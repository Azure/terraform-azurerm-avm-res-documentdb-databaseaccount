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
