variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
  Defaults to `{}`. A map of diagnostic settings to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `name`                                     - (Optional) - The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
  - `log_categories`                           - (Optional) - Defaults to `[]`. A set of log categories to export. Possible values are: `DataPlaneRequests`, `MongoRequests`, `CassandraRequests`,  `GremlinRequests`, `QueryRuntimeStatistics`, `PartitionKeyStatistics`, `PartitionKeyRUConsumption`, `ControlPlaneRequests` or `TableApiRequests`.
  - `log_groups`                               - (Optional) - Defaults to `[]` if log_categories is set, if not it defaults to `["allLogs", "audit"]`. A set of log groups to send to export. Possible values are `allLogs` and `audit`.
  - `metric_categories`                        - (Optional) - Defaults to `["AllMetrics"]`. A set of metric categories to export.
  - `log_analytics_destination_type`           - (Optional) - Defaults to `Dedicated`. The destination log analytics workspace table for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
  - `workspace_resource_id`                    - (Optional) - The resource ID of the log analytics workspace to send logs and metrics to.
  - `storage_account_resource_id`              - (Optional) - The resource ID of the storage account to send logs and metrics to.
  - `event_hub_authorization_rule_resource_id` - (Optional) - The resource ID of the event hub authorization rule to send logs and metrics to.
  - `event_hub_name`                           - (Optional) - The name of the event hub. If none is specified, the default event hub will be selected.
  - `marketplace_partner_resource_id`          - (Optional) - The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.

  > Note: See more in CLI: az monitor diagnostic-settings categories list --resource {cosmosAccountResourceId}

  Example Inputs:
  ```hcl
  diagnostic_settings = {
    diagnostic1 = {
      event_hub_name                           = "hub-name"
      log_analytics_destination_type           = "Dedicated"
      name                                     = "diagnostics"
      event_hub_authorization_rule_resource_id = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.EventHub/namespaces/{eventHubNamespaceName}/authorizationRules/{authorizationRuleName}"

      #log_categories = ["DataPlaneRequests", "MongoRequests", "CassandraRequests",  "GremlinRequests", "QueryRuntimeStatistics", "PartitionKeyStatistics", "PartitionKeyRUConsumption", "ControlPlaneRequests",  "TableApiRequests"]

      metric_categories           = ["AllMetrics"]
      log_groups                  = ["allLogs", "audit"]
      workspace_resource_id       = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}"
      storage_account_resource_id = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{storageAccountName}"
    }
  }
  ```  
  DESCRIPTION

  validation {
    condition = alltrue([
      for _, v in var.diagnostic_settings :
      alltrue([
        for c in v.metric_categories :
        c == null ? false : contains(["AllMetrics"], c)
      ])
    ])
    error_message = "The metric_categories parameter if specified can only be 'AllMetrics'."
  }

  validation {
    condition = alltrue([
      for _, v in var.diagnostic_settings :
      alltrue([
        for c in v.log_groups :
        c == null ? false : contains(["allLogs", "audit"], c)
      ])
    ])
    error_message = "The 'log_groups' parameter if specified can only be 'allLogs' and 'audit'."
  }

  validation {
    condition = alltrue([
      for _, v in var.diagnostic_settings :
      alltrue([
        for c in v.log_categories :
        contains(["DataPlaneRequests", "MongoRequests", "CassandraRequests", "GremlinRequests", "QueryRuntimeStatistics", "PartitionKeyStatistics", "PartitionKeyRUConsumption", "ControlPlaneRequests", "TableApiRequests"], c)
      ])
    ])
    error_message = "The 'log_categories' parameter if specified can only be 'DataPlaneRequests', 'MongoRequests', 'CassandraRequests',  'GremlinRequests', 'QueryRuntimeStatistics', 'PartitionKeyStatistics', 'PartitionKeyRUConsumption', 'ControlPlaneRequests',  'TableApiRequests'."
  }

  validation {
    condition = alltrue([
      for _, v in var.diagnostic_settings :
      contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)
    ])
    error_message = "'log_analytics_destination_type' must be one of: 'Dedicated', 'AzureDiagnostics'."
  }

  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || (v.event_hub_name != null && v.event_hub_authorization_rule_resource_id != null) || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of 'workspace_resource_id', 'storage_account_resource_id', 'marketplace_partner_resource_id', or 'event_hub_authorization_rule_resource_id' and 'event_hub_name' together, must be set."
  }

  validation {
    condition = alltrue([
      for _, v in var.diagnostic_settings :
      v.log_categories != null || v.log_groups != null || v.metric_categories != null
    ])
    error_message = "At least one of 'log_categories', 'log_groups', or 'metric_categories' must be set."
  }

  validation {
    condition = alltrue([
      for _, v in var.diagnostic_settings :
      v.storage_account_resource_id == null || can(regex("^/subscriptions/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/resourceGroups/.+/providers/Microsoft.Storage/storageAccounts/.+$", v.storage_account_resource_id))
    ])
    error_message = "The 'storage_account_resource_id' if specified must have the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{storageAccountName}'"
  }

  validation {
    condition = alltrue([
      for _, v in var.diagnostic_settings :
      v.workspace_resource_id == null || can(regex("^/subscriptions/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/resourceGroups/.+/providers/Microsoft.OperationalInsights/workspaces/.+$", v.workspace_resource_id))
    ])
    error_message = "The 'workspace_resource_id' if specified must have the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}'"
  }

  validation {
    condition = alltrue([
      for _, v in var.diagnostic_settings :
      v.event_hub_authorization_rule_resource_id == null || can(regex("^/subscriptions/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/resourceGroups/.+/providers/Microsoft.EventHub/namespaces/.+/authorizationRules/.+$", v.event_hub_authorization_rule_resource_id))
    ])
    error_message = "The 'event_hub_authorization_rule_resource_id' if specified must have the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.EventHub/namespaces/{eventHubNamespaceName}/authorizationRules/{authorizationRuleName}'"
  }
}