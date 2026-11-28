variable "ignore_body_changes" {
  type = object({
    authorization_locks                                                          = optional(list(string), [])
    authorization_role_assignments                                               = optional(list(string), [])
    documentdb_database_accounts                                                 = optional(list(string), [])
    documentdb_database_accounts_gremlin_databases                               = optional(list(string), [])
    documentdb_database_accounts_gremlin_databases_graphs                        = optional(list(string), [])
    documentdb_database_accounts_mongodb_databases                               = optional(list(string), [])
    documentdb_database_accounts_mongodb_databases_collections                   = optional(list(string), [])
    documentdb_database_accounts_services                                        = optional(list(string), [])
    documentdb_database_accounts_sql_databases                                   = optional(list(string), [])
    documentdb_database_accounts_sql_databases_containers                        = optional(list(string), [])
    documentdb_database_accounts_sql_databases_containers_stored_procedures      = optional(list(string), [])
    documentdb_database_accounts_sql_databases_containers_triggers               = optional(list(string), [])
    documentdb_database_accounts_sql_databases_containers_user_defined_functions = optional(list(string), [])
    insights_diagnostic_settings                                                 = optional(list(string), [])
    network_private_endpoints                                                    = optional(list(string), [])
    network_private_endpoints_private_dns_zone_groups                            = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative dot paths to ignore on AzAPI resources that support this argument.
The provider does not support this setting on `azapi_update_resource`, which this module uses for throughput.
Changes take effect only after apply.
Ignored configuration is not sent to Azure until its path is removed.

- `authorization_locks` - Paths ignored on the management locks of the account and private endpoints.
- `authorization_role_assignments` - Paths ignored on the role assignments of the account and private endpoints.
- `documentdb_database_accounts` - Paths ignored on the Cosmos DB account.
- `documentdb_database_accounts_gremlin_databases` - Paths ignored on Gremlin databases.
- `documentdb_database_accounts_gremlin_databases_graphs` - Paths ignored on Gremlin graphs.
- `documentdb_database_accounts_mongodb_databases` - Paths ignored on MongoDB databases.
- `documentdb_database_accounts_mongodb_databases_collections` - Paths ignored on MongoDB collections.
- `documentdb_database_accounts_services` - Paths ignored on the SQL dedicated gateway.
- `documentdb_database_accounts_sql_databases` - Paths ignored on SQL databases.
- `documentdb_database_accounts_sql_databases_containers` - Paths ignored on SQL containers.
- `documentdb_database_accounts_sql_databases_containers_stored_procedures` - Paths ignored on SQL stored procedures.
- `documentdb_database_accounts_sql_databases_containers_triggers` - Paths ignored on SQL triggers.
- `documentdb_database_accounts_sql_databases_containers_user_defined_functions` - Paths ignored on SQL user-defined functions.
- `insights_diagnostic_settings` - Paths ignored on diagnostic settings.
- `network_private_endpoints` - Paths ignored on private endpoints.
- `network_private_endpoints_private_dns_zone_groups` - Paths ignored on private DNS zone groups.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    authorization_locks                                                            = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    authorization_role_assignments                                                 = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    documentdb_database_accounts                                                   = optional(string, "Microsoft.DocumentDB/databaseAccounts@2026-03-15")
    documentdb_database_accounts_gremlin_databases                                 = optional(string, "Microsoft.DocumentDB/databaseAccounts/gremlinDatabases@2026-03-15")
    documentdb_database_accounts_gremlin_databases_graphs                          = optional(string, "Microsoft.DocumentDB/databaseAccounts/gremlinDatabases/graphs@2026-03-15")
    documentdb_database_accounts_gremlin_databases_graphs_throughput_settings      = optional(string, "Microsoft.DocumentDB/databaseAccounts/gremlinDatabases/graphs/throughputSettings@2026-03-15")
    documentdb_database_accounts_gremlin_databases_throughput_settings             = optional(string, "Microsoft.DocumentDB/databaseAccounts/gremlinDatabases/throughputSettings@2026-03-15")
    documentdb_database_accounts_mongodb_databases                                 = optional(string, "Microsoft.DocumentDB/databaseAccounts/mongodbDatabases@2026-03-15")
    documentdb_database_accounts_mongodb_databases_collections                     = optional(string, "Microsoft.DocumentDB/databaseAccounts/mongodbDatabases/collections@2026-03-15")
    documentdb_database_accounts_mongodb_databases_collections_throughput_settings = optional(string, "Microsoft.DocumentDB/databaseAccounts/mongodbDatabases/collections/throughputSettings@2026-03-15")
    documentdb_database_accounts_mongodb_databases_throughput_settings             = optional(string, "Microsoft.DocumentDB/databaseAccounts/mongodbDatabases/throughputSettings@2026-03-15")
    documentdb_database_accounts_services                                          = optional(string, "Microsoft.DocumentDB/databaseAccounts/services@2026-03-15")
    documentdb_database_accounts_sql_databases                                     = optional(string, "Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2026-03-15")
    documentdb_database_accounts_sql_databases_containers                          = optional(string, "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2026-03-15")
    documentdb_database_accounts_sql_databases_containers_stored_procedures        = optional(string, "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/storedProcedures@2026-03-15")
    documentdb_database_accounts_sql_databases_containers_throughput_settings      = optional(string, "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/throughputSettings@2026-03-15")
    documentdb_database_accounts_sql_databases_containers_triggers                 = optional(string, "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/triggers@2026-03-15")
    documentdb_database_accounts_sql_databases_containers_user_defined_functions   = optional(string, "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/userDefinedFunctions@2026-03-15")
    documentdb_database_accounts_sql_databases_throughput_settings                 = optional(string, "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/throughputSettings@2026-03-15")
    insights_diagnostic_settings                                                   = optional(string, "Microsoft.Insights/diagnosticSettings@2021-05-01-preview")
    network_private_endpoints                                                      = optional(string, "Microsoft.Network/privateEndpoints@2025-01-01")
    network_private_endpoints_private_dns_zone_groups                              = optional(string, "Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2025-01-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions, in `<provider>/<resource>@<api-version>` form. Each key defaults to a tested value; supply only the keys you want to override.

- `authorization_locks` - The management locks of the account and private endpoints.
- `authorization_role_assignments` - The role assignments of the account and private endpoints.
- `documentdb_database_accounts` - The Cosmos DB account, and reading its keys and connection strings.
- `documentdb_database_accounts_gremlin_databases` - Gremlin databases.
- `documentdb_database_accounts_gremlin_databases_graphs` - Gremlin graphs.
- `documentdb_database_accounts_gremlin_databases_graphs_throughput_settings` - Throughput changes of Gremlin graphs.
- `documentdb_database_accounts_gremlin_databases_throughput_settings` - Throughput changes of Gremlin databases.
- `documentdb_database_accounts_mongodb_databases` - MongoDB databases.
- `documentdb_database_accounts_mongodb_databases_collections` - MongoDB collections.
- `documentdb_database_accounts_mongodb_databases_collections_throughput_settings` - Throughput changes of MongoDB collections.
- `documentdb_database_accounts_mongodb_databases_throughput_settings` - Throughput changes of MongoDB databases.
- `documentdb_database_accounts_services` - The SQL dedicated gateway.
- `documentdb_database_accounts_sql_databases` - SQL databases.
- `documentdb_database_accounts_sql_databases_containers` - SQL containers.
- `documentdb_database_accounts_sql_databases_containers_stored_procedures` - SQL stored procedures.
- `documentdb_database_accounts_sql_databases_containers_throughput_settings` - Throughput changes of SQL containers.
- `documentdb_database_accounts_sql_databases_containers_triggers` - SQL triggers.
- `documentdb_database_accounts_sql_databases_containers_user_defined_functions` - SQL user-defined functions.
- `documentdb_database_accounts_sql_databases_throughput_settings` - Throughput changes of SQL databases.
- `insights_diagnostic_settings` - Diagnostic settings.
- `network_private_endpoints` - Private endpoints.
- `network_private_endpoints_private_dns_zone_groups` - Private DNS zone groups.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to every supported AzAPI resource declared by this module.
Defaults to null (no custom retry).

- `error_message_regex` - Error-message patterns that trigger a retry.
- `interval_seconds` - Initial interval between retries in seconds.
- `max_interval_seconds` - Maximum interval between retries in seconds.
DESCRIPTION
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Per-operation timeouts applied to every supported AzAPI resource declared by this module.
Defaults to null (provider defaults). Values are Go duration strings.

- `create` - Create timeout.
- `read` - Read timeout.
- `update` - Update timeout.
- `delete` - Delete timeout.
DESCRIPTION
}
