resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name = coalesce(each.value.name, "diag-${each.key}")

  target_resource_id = azurerm_cosmosdb_account.this.id

  eventhub_name                  = each.value.event_hub_name
  log_analytics_workspace_id     = each.value.workspace_resource_id
  storage_account_id             = each.value.storage_account_resource_id
  log_analytics_destination_type = each.value.log_analytics_destination_type
  partner_solution_id            = each.value.marketplace_partner_resource_id
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id

  dynamic "enabled_log" {
    for_each = each.value.log_categories

    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_log" {
    for_each = length(each.value.log_categories) == 0 ? each.value.log_groups : []

    content {
      category_group = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = each.value.metric_categories

    content {
      category = metric.value
    }
  }

  depends_on = [time_sleep.wait_60_seconds_for_destroy]
}