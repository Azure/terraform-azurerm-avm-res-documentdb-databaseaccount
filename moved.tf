# The resources that versions 0.12.x and earlier managed with the AzureRM provider moved to AzAPI. They are
# adopted in place and updated with the same settings.
moved {
  from = azurerm_cosmosdb_account.this
  to   = azapi_resource.this
}

moved {
  from = azurerm_cosmosdb_sql_database.this
  to   = azapi_resource.sql_databases
}

moved {
  from = azurerm_cosmosdb_sql_container.this
  to   = azapi_resource.sql_containers
}

moved {
  from = azurerm_cosmosdb_sql_function.this
  to   = azapi_resource.sql_functions
}

moved {
  from = azurerm_cosmosdb_sql_stored_procedure.this
  to   = azapi_resource.sql_stored_procedures
}

moved {
  from = azurerm_cosmosdb_sql_trigger.this
  to   = azapi_resource.sql_triggers
}

moved {
  from = azurerm_cosmosdb_sql_dedicated_gateway.this
  to   = azapi_resource.sql_dedicated_gateway
}

moved {
  from = azurerm_cosmosdb_mongo_database.this
  to   = azapi_resource.mongo_databases
}

moved {
  from = azurerm_cosmosdb_mongo_collection.this
  to   = azapi_resource.mongo_collections
}

moved {
  from = azurerm_cosmosdb_gremlin_database.this
  to   = azapi_resource.gremlin_databases
}

moved {
  from = azurerm_cosmosdb_gremlin_graph.this
  to   = azapi_resource.gremlin_graphs
}

moved {
  from = azurerm_management_lock.this
  to   = azapi_resource.locks
}

moved {
  from = azurerm_role_assignment.this
  to   = azapi_resource.role_assignments
}

moved {
  from = azurerm_monitor_diagnostic_setting.this
  to   = azapi_resource.diagnostic_settings
}

moved {
  from = azurerm_private_endpoint.this_managed_dns_zone_groups
  to   = azapi_resource.private_endpoints
}

moved {
  from = azurerm_private_endpoint.this_unmanaged_dns_zone_groups
  to   = azapi_resource.private_endpoints_unmanaged
}

# Application security groups are now set on the private endpoints. The associations are removed from the state
# and kept in Azure.
removed {
  from = azurerm_private_endpoint_application_security_group_association.this

  lifecycle {
    destroy = false
  }
}
