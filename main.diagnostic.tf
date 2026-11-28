resource "azapi_resource" "diagnostic_settings" {
  for_each = var.diagnostic_settings

  name      = coalesce(each.value.name, "diag-${each.key}")
  parent_id = azapi_resource.this.id
  type      = var.resource_types.insights_diagnostic_settings
  body = {
    properties = {
      eventHubAuthorizationRuleId = each.value.event_hub_authorization_rule_resource_id
      eventHubName                = each.value.event_hub_name
      logAnalyticsDestinationType = each.value.log_analytics_destination_type
      # As before, log category groups are only sent when no log categories are.
      logs = length(each.value.log_categories) > 0 ? [
        for category in each.value.log_categories : { category = category, categoryGroup = null, enabled = true }
        ] : [
        for group in each.value.log_groups : { category = null, categoryGroup = group, enabled = true }
      ]
      marketplacePartnerId = each.value.marketplace_partner_resource_id
      # Azure lists every metric category, disabled, when none is sent, so an empty list is not sent.
      metrics          = length(each.value.metric_categories) > 0 ? [for category in each.value.metric_categories : { category = category, enabled = true }] : null
      storageAccountId = each.value.storage_account_resource_id
      workspaceId      = each.value.workspace_resource_id
    }
  }
  ignore_body_changes  = length(var.ignore_body_changes.insights_diagnostic_settings) > 0 ? var.ignore_body_changes.insights_diagnostic_settings : null
  ignore_casing        = true
  ignore_null_property = true
  # Azure returns every log category group and metric category of the account, disabling those that were not sent.
  # List items are matched by category and items that are not configured are ignored, so they are not reported as
  # changes.
  ignore_other_items_in_list = ["properties.logs", "properties.metrics"]
  list_unique_id_property = {
    "properties.logs"    = "category, categoryGroup"
    "properties.metrics" = "category"
  }
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [time_sleep.wait_180_seconds_for_destroy]
}
