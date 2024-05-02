output "resource" {
  value       = azurerm_servicebus_namespace.this
  description = "The service bus namespace created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace.html#attributes-reference"
  sensitive   = true
}

output "resource_authorization_rules" {
  value       = azurerm_servicebus_namespace_authorization_rule.this
  description = "The service bus namespace authorization rules created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace_authorization_rule#attributes-reference"
  sensitive   = true
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

output "resource_queues" {
  value       = merge(azurerm_servicebus_queue.base_queues, azurerm_servicebus_queue.forward_queues)
  description = "The service bus queues created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint_application_security_group_association#attributes-reference"
}

output "resource_queues_authorization_rules" {
  value       = azurerm_servicebus_queue_authorization_rule.this
  description = "The service bus queues authorization rules created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_queue_authorization_rule#attributes-reference"
  sensitive   = true
}

output "resource_topics" {
  value       = azurerm_servicebus_topic.this
  description = "The service bus topics created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_topic.html#attributes-reference"
}

output "resource_topics_authorization_rules" {
  value       = azurerm_servicebus_topic_authorization_rule.this
  description = "The service bus topics authorization rules created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_topic_authorization_rule#attributes-reference"
  sensitive   = true
}

output "resource_topics_subscriptions" {
  value       = merge(azurerm_servicebus_subscription.base_topics, azurerm_servicebus_subscription.forward_topics)
  description = "The service bus topic subscriptions created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_subscription#attributes-reference"
}