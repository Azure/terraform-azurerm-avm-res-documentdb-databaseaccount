output "name" {
  description = "The name of the cosmos db account created."
  value       = azurerm_cosmosdb_account.this.name
}

output "resource" {
  description = "The cosmos db account created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_account#attributes-reference"
  sensitive   = true
  value       = azurerm_cosmosdb_account.this
}

output "resource_diagnostic_settings" {
  description = "The diagnostic settings created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting#attributes-reference"
  value       = azurerm_monitor_diagnostic_setting.this
}

output "resource_id" {
  description = "The resource ID of the cosmos db account created."
  value       = azurerm_cosmosdb_account.this.id
}

output "resource_locks" {
  description = "The management locks created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock#attributes-reference"
  value       = azurerm_management_lock.this
}

output "resource_private_endpoints" {
  description = "A map of the private endpoints created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint#attributes-reference"
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
}

output "resource_private_endpoints_application_security_group_association" {
  description = "The private endpoint application security group associations created"
  value       = azurerm_private_endpoint_application_security_group_association.this
}

output "resource_role_assignments" {
  description = "The role assignments created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment#attributes-reference"
  value       = azurerm_role_assignment.this
}

output "sql_containers" {
  description = "The value of the sql containers created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_container#attributes-reference"
  value       = azurerm_cosmosdb_sql_container.this
}

output "sql_databases" {
  description = "The value of the sql databases created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_database#attributes-reference"
  value       = azurerm_cosmosdb_sql_database.this
}

output "sql_dedicated_gateway" {
  description = "The value of the sql dedicated gateway created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_dedicated_gateway#attributes-reference"
  value       = azurerm_cosmosdb_sql_dedicated_gateway.this
}

output "sql_functions" {
  description = "The value of the sql functions created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_function#attributes-reference"
  value       = azurerm_cosmosdb_sql_function.this
}

output "sql_stored_procedures" {
  description = "The value of the sql stored procedures created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_stored_procedure#attributes-reference"
  value       = azurerm_cosmosdb_sql_stored_procedure.this
}

output "sql_triggers" {
  description = "The value of the sql triggers created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_trigger#attributes-reference"
  value       = azurerm_cosmosdb_sql_trigger.this
}
