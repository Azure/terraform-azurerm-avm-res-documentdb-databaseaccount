output "name" {
  value       = azurerm_cosmosdb_account.this.name
  description = "The name of the cosmos db account created."
}

output "resource_id" {
  value       = azurerm_cosmosdb_account.this.id
  description = "The resource ID of the cosmos db account created."
}

output "resource" {
  value       = azurerm_cosmosdb_account.this
  description = "The cosmos db account created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_account#attributes-reference"
  sensitive   = true
}

output "sql_databases" {
  value       = azurerm_cosmosdb_sql_database.this
  description = "The value of the sql databases created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_database#attributes-reference"
}

output "sql_containers" {
  value       = azurerm_cosmosdb_sql_container.this
  description = "The value of the sql containers created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_container#attributes-reference"
}

output "sql_dedicated_gateway" {
  value       = azurerm_cosmosdb_sql_dedicated_gateway.this
  description = "The value of the sql dedicated gateway created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_dedicated_gateway#attributes-reference"
}

output "sql_functions" {
  value       = azurerm_cosmosdb_sql_function.this
  description = "The value of the sql functions created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_function#attributes-reference"
}

output "sql_stored_procedures" {
  value       = azurerm_cosmosdb_sql_stored_procedure.this
  description = "The value of the sql stored procedures created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_stored_procedure#attributes-reference"
}

output "sql_triggers" {
  value       = azurerm_cosmosdb_sql_trigger.this
  description = "The value of the sql triggers created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_sql_trigger#attributes-reference"
}

output "resource_diagnostic_settings" {
  value       = azurerm_monitor_diagnostic_setting.this
  description = "The diagnostic settings created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting#attributes-reference"
}

output "resource_role_assignments" {
  value       = azurerm_role_assignment.this
  description = "The role assignments created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment#attributes-reference"
}

output "resource_locks" {
  value       = azurerm_management_lock.this
  description = "The management locks created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock#attributes-reference"
}

output "resource_private_endpoints" {
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
  description = "A map of the private endpoints created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint#attributes-reference"
}

output "resource_private_endpoints_application_security_group_association" {
  value       = azurerm_private_endpoint_application_security_group_association.this
  description = "The private endpoint application security group associations created"
}