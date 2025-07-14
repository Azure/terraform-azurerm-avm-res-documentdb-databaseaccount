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

output "mongo_databases_detailed" {
  description = "Detailed MongoDB databases with enhanced attributes"
  value       = module.cosmos.mongo_databases
}

output "connection_strings" {
  description = "MongoDB connection strings"
  value       = module.cosmos.cosmosdb_mongodb_connection_strings
  sensitive   = true
}

output "all_resources_summary" {
  description = "Summary of all resources created"
  value       = module.cosmos.all_resources
}