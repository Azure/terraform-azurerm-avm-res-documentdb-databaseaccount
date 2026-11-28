resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.documentdb_database_accounts
  body = {
    kind       = local.kind
    properties = local.account_properties
  }
  ignore_body_changes  = length(var.ignore_body_changes.documentdb_database_accounts) > 0 ? var.ignore_body_changes.documentdb_database_accounts : null
  ignore_casing        = true
  ignore_null_property = true
  # The AzureRM provider sent these lists in the order of its hash sets, and Azure kept that order. The items
  # are matched by these properties, so a different order is not a change.
  list_unique_id_property = {
    "properties.capabilities"        = "name"
    "properties.ipRules"             = "ipAddressOrRange"
    "properties.locations"           = "locationName"
    "properties.virtualNetworkRules" = "id"
  }
  # The AzureRM provider replaced the account when one of these settings changed, because Azure cannot change
  # them in place. While the prior value is null, as it is straight after upgrading from AzureRM, nothing is
  # replaced.
  replace_triggers_external_values = local.account_replace_triggers
  response_export_values = {
    analytical_storage_schema_type = "properties.analyticalStorageConfiguration.schemaType"
    document_endpoint              = "properties.documentEndpoint"
    read_endpoints                 = "properties.readLocations[].documentEndpoint"
    write_endpoints                = "properties.writeLocations[].documentEndpoint"
  }
  retry = var.retry
  # The AzAPI provider sends both identity types as `SystemAssigned, UserAssigned`, which Azure accepts but the
  # embedded schema does not, so the schema is not checked for an account with both.
  schema_validation_enabled = !(var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0)
  tags                      = var.tags

  dynamic "identity" {
    for_each = local.managed_identities.system_assigned_user_assigned

    content {
      type         = identity.value.type
      identity_ids = tolist(identity.value.user_assigned_resource_ids)
    }
  }

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    precondition {
      condition     = var.backup.type == local.continuous_backup_policy && var.multiple_write_locations_enabled ? false : true
      error_message = "Continuous backup mode and multiple write locations cannot be enabled together."
    }
    precondition {
      condition     = var.analytical_storage_enabled && var.partition_merge_enabled ? false : true
      error_message = "Analytical storage and partition merge cannot be enabled together."
    }
    precondition {
      condition     = contains(var.capabilities, "EnableServerless") && length(local.normalized_geo_locations) > 1 ? false : true
      error_message = "Serverless mode can only be enabled in a single region."
    }
    precondition {
      condition     = !(length(var.sql_databases) > 0 && length(var.mongo_databases) > 0)
      error_message = "You can only create either SQL or MongoDB databases, not both."
    }
  }
}

# Azure returns the display names of the account's regions, for example `West US 2`. The configured regions are
# sent with the same names, so that they compare equal.
data "azapi_resource_action" "locations" {
  action      = "locations"
  method      = "GET"
  resource_id = "/subscriptions/${local.subscription_id}"
  type        = "Microsoft.Resources/subscriptions@2022-12-01"
  response_export_values = {
    locations = "value[].{name: name, display_name: displayName}"
  }
  retry = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      read = timeouts.value.read
    }
  }
}

# The account's document endpoint does not change, so it is read from Azure when the account already exists,
# rather than from the account resource, whose outputs are unknown while the account has changes pending. This
# keeps `endpoint` known when planning the upgrade from an earlier version, so resources that use it are not
# changed. An account that is about to be created, or recreated in another region, uses the resource's value.
data "azapi_resource" "account" {
  name             = var.name
  parent_id        = var.parent_id
  type             = var.resource_types.documentdb_database_accounts
  ignore_not_found = true
  response_export_values = {
    document_endpoint = "properties.documentEndpoint"
    location          = "location"
  }
  retry = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      read = timeouts.value.read
    }
  }
}

# The AzureRM provider read the keys and connection strings with the account. They are read here when the
# account is created, or upgraded from an earlier version of this module, and not on later plans: reading them
# is a POST, which a `ReadOnly` lock blocks. The lock is created after them.
resource "azapi_resource_action" "secrets" {
  for_each = local.secret_actions

  action                           = each.value.action
  method                           = "POST"
  resource_id                      = azapi_resource.this.id
  type                             = var.resource_types.documentdb_database_accounts
  response_export_values           = []
  retry                            = var.retry
  sensitive_response_export_values = each.value.exports

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    # Recreating the account, for example in another region, keeps its resource ID and creates new keys.
    replace_triggered_by = [
      azapi_resource.this.location,
      azapi_resource.this.replace_triggers_external_values,
    ]
  }
}

# While upgrading from an earlier version, the keys and connection strings are also read during plan, so that
# they are known and resources that use them are not changed.
data "azapi_resource_action" "secrets" {
  for_each = var.avm_managed_migration_enabled ? local.secret_actions : {}

  action                           = each.value.action
  method                           = "POST"
  resource_id                      = local.account_resource_id
  type                             = var.resource_types.documentdb_database_accounts
  response_export_values           = []
  retry                            = var.retry
  sensitive_response_export_values = each.value.exports

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      read = timeouts.value.read
    }
  }
}

resource "time_sleep" "wait_180_seconds_for_destroy" {
  count = length(var.diagnostic_settings) > 0 ? 1 : 0

  destroy_duration = "180s"
  triggers = {
    account_id = azapi_resource.this.id
  }
}
