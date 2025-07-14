output "cosmos_account_details" {
  description = "Complete Cosmos DB account details including endpoints and identity"
  value = {
    name            = module.cosmos.name
    resource_id     = module.cosmos.resource_id
    endpoint        = module.cosmos.endpoint
    read_endpoints  = module.cosmos.read_endpoints
    write_endpoints = module.cosmos.write_endpoints
    identity        = module.cosmos.identity
    geo_locations   = module.cosmos.geo_locations
  }
}

output "sql_databases_detailed" {
  description = "Detailed SQL databases with enhanced attributes"
  value       = module.cosmos.sql_databases
}

output "sql_dedicated_gateway_details" {
  description = "SQL dedicated gateway details"
  value       = module.cosmos.sql_dedicated_gateway
}

output "infrastructure_resources" {
  description = "Infrastructure resources created (locks, diagnostics, etc.)"
  value = {
    diagnostic_settings = module.cosmos.resource_diagnostic_settings
    locks               = module.cosmos.resource_locks
    role_assignments    = module.cosmos.resource_role_assignments
  }
  sensitive = false
}

output "legacy_sql_databases" {
  description = "Legacy output format for backwards compatibility"
  value       = module.cosmos.sql_databases
}
