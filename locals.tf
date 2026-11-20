locals {
  account_scope_type            = "Account"
  bounded_staleness_consistency = "BoundedStaleness"
  cmk_keyvault_name             = var.customer_managed_key != null ? element(split("/", var.customer_managed_key.key_vault_resource_id), 8) : null
  continuous_backup_policy      = "Continuous"
  default_geo_location = toset([{
    failover_priority = 0
    zone_redundant    = true
    location          = var.location
  }])
  managed_identities = {
    system_assigned_user_assigned = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? {
      this = {
        type                       = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
    system_assigned = var.managed_identities.system_assigned ? {
      this = {
        type = "SystemAssigned"
      }
    } : {}
    user_assigned = length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      this = {
        type                       = "UserAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
  }
  normalized_cmk_default_identity_type = var.customer_managed_key != null ? "UserAssignedIdentity=${var.customer_managed_key.user_assigned_identity.resource_id}" : null
  normalized_cmk_key_url               = var.customer_managed_key != null ? "https://${local.cmk_keyvault_name}.vault.azure.net/keys/${var.customer_managed_key.key_name}" : null
  normalized_geo_locations             = coalesce(var.geo_locations, local.default_geo_location)
  periodic_backup_policy               = "Periodic"
  private_endpoint_scope_type          = "PrivateEndpoint"
  serverless_capability                = "EnableServerless"
  trimmed_ip_range_filter              = [for value in var.ip_range_filter : trimspace(value)]
}

locals {
  # The settings the AzureRM provider sent, including its defaults, so that upgrading changes nothing in Azure.
  # Settings that do not apply are null, and are not sent.
  account_properties = {
    analyticalStorageConfiguration = var.analytical_storage_config == null ? null : {
      schemaType = var.analytical_storage_config.schema_type
    }
    apiProperties = local.kind == "MongoDB" ? {
      serverVersion = var.mongo_server_version
    } : null
    # The backup policy is a union on `type`, so only the settings of the configured type may be sent.
    backupPolicy = {
      for name, value in {
        type = var.backup.type
        continuousModeProperties = var.backup.type == local.continuous_backup_policy && var.backup.tier != null ? {
          tier = var.backup.tier
        } : null
        periodicModeProperties = var.backup.type == local.periodic_backup_policy ? {
          backupIntervalInMinutes        = var.backup.interval_in_minutes
          backupRetentionIntervalInHours = var.backup.retention_in_hours
          backupStorageRedundancy        = var.backup.storage_redundancy
        } : null
      } : name => value if value != null
    }
    capabilities = [for name in local.capability_names : { name = name }]
    capacity = {
      totalThroughputLimit = var.capacity.total_throughput_limit
    }
    consistencyPolicy = {
      defaultConsistencyLevel = var.consistency_policy.consistency_level
      maxIntervalInSeconds    = var.consistency_policy.consistency_level == local.bounded_staleness_consistency ? var.consistency_policy.max_interval_in_seconds : 5
      maxStalenessPrefix      = var.consistency_policy.consistency_level == local.bounded_staleness_consistency ? var.consistency_policy.max_staleness_prefix : 100
    }
    cors = var.cors_rule == null ? null : [
      {
        allowedHeaders  = join(",", var.cors_rule.allowed_headers)
        allowedMethods  = join(",", var.cors_rule.allowed_methods)
        allowedOrigins  = join(",", var.cors_rule.allowed_origins)
        exposedHeaders  = join(",", var.cors_rule.exposed_headers)
        maxAgeInSeconds = coalesce(var.cors_rule.max_age_in_seconds, 0) > 0 ? var.cors_rule.max_age_in_seconds : null
      }
    ]
    databaseAccountOfferType           = "Standard"
    defaultIdentity                    = coalesce(local.normalized_cmk_default_identity_type, "FirstPartyIdentity")
    disableKeyBasedMetadataWriteAccess = !var.access_key_metadata_writes_enabled
    disableLocalAuth                   = local.local_authentication_disabled
    enableAnalyticalStorage            = var.analytical_storage_enabled
    enableAutomaticFailover            = var.automatic_failover_enabled
    enableBurstCapacity                = var.burst_capacity_enabled
    enableFreeTier                     = var.free_tier_enabled
    enableMultipleWriteLocations       = local.multiple_write_locations_enabled
    enablePartitionMerge               = var.partition_merge_enabled
    ipRules                            = [for ip_range in local.trimmed_ip_range_filter : { ipAddressOrRange = ip_range }]
    isVirtualNetworkFilterEnabled      = length(var.virtual_network_rules) > 0
    keyVaultKeyUri                     = local.normalized_cmk_key_url
    locations = [
      for location in local.normalized_geo_locations : {
        failoverPriority = location.failover_priority
        isZoneRedundant  = location.zone_redundant
        locationName     = lookup(local.location_display_names, lower(replace(location.location, " ", "")), location.location)
      }
    ]
    minimalTlsVersion           = var.minimal_tls_version
    networkAclBypass            = var.network_acl_bypass_for_azure_services ? "AzureServices" : "None"
    networkAclBypassResourceIds = tolist(var.network_acl_bypass_resource_ids)
    publicNetworkAccess         = var.public_network_access_enabled ? "Enabled" : "Disabled"
    virtualNetworkRules = [
      for rule in var.virtual_network_rules : {
        id                               = rule.subnet_id
        ignoreMissingVNetServiceEndpoint = false
      }
    ]
  }
  # True when the account already exists in the configured region, so it is updated in place rather than created
  # or recreated.
  account_exists = try(data.azapi_resource.account.exists && lower(replace(data.azapi_resource.account.output.location, " ", "")) == lower(replace(var.location, " ", "")), false)
  account_replace_triggers = {
    capabilities      = sort([for capability in var.capabilities : lower(capability.name) if !contains(local.capabilities_updatable_in_place, lower(capability.name))])
    free_tier_enabled = var.free_tier_enabled
    key_vault_key_url = local.normalized_cmk_key_url == null ? null : lower(local.normalized_cmk_key_url)
    kind              = local.kind
  }
  # Terraform waits until apply to read a data source that refers directly to a resource with changes pending.
  # Referring to an existing account by this ID lets data sources read from it during plan instead.
  account_resource_id = local.account_exists ? data.azapi_resource.account.id : azapi_resource.this.id
  # Azure adds the `EnableMongo` capability to MongoDB accounts of server version 3.6 or later, so it is sent with
  # the configured capabilities. Otherwise the account would appear to change on every plan.
  capability_names = distinct(concat(
    [for capability in var.capabilities : capability.name],
    local.kind == "MongoDB" && var.mongo_server_version != "3.2" ? ["EnableMongo"] : [],
  ))
  # The capabilities that the AzureRM provider added to an existing account, or removed from it, without
  # replacing it. Changing any other capability replaced the account.
  capabilities_updatable_in_place = [
    "allowselfserveupgradetomongo36",
    "deleteallitemsbypartitionkey",
    "disableratelimitingresponses",
    "enableaggregationpipeline",
    "enablefabricnetworkaclbypass",
    "enablemongo16mbdocumentsupport",
    "enablemongoretryablewrites",
    "enablemongorolebasedaccesscontrol",
    "enablepartialuniqueindex",
    "enablettloncustompath",
    "enableuniquecompoundnesteddocs",
    "mongodbv3.4",
    "mongoenabledoclevelttl",
  ]
  connection_strings               = { for connection_string in try(local.secrets.connection_strings.connectionStrings, []) : connection_string.description => connection_string.connectionString }
  kind                             = length(var.mongo_databases) > 0 ? "MongoDB" : "GlobalDocumentDB"
  local_authentication_disabled    = (length(var.mongo_databases) > 0 || length(var.gremlin_databases) > 0) ? false : var.local_authentication_disabled
  location_display_names           = { for location in data.azapi_resource_action.locations.output.locations : location.name => location.display_name }
  multiple_write_locations_enabled = var.backup.type == local.periodic_backup_policy ? var.multiple_write_locations_enabled : false
  resource_group_name              = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id).resource_group_name
  secret_actions = {
    connection_strings = {
      action  = "listConnectionStrings"
      exports = ["connectionStrings"]
    }
    keys = {
      action  = "listKeys"
      exports = ["primaryMasterKey", "secondaryMasterKey"]
    }
    readonly_keys = {
      action  = "readonlykeys"
      exports = ["primaryReadonlyMasterKey", "secondaryReadonlyMasterKey"]
    }
  }
  secrets = {
    for key in keys(local.secret_actions) : key => var.avm_managed_migration_enabled ? data.azapi_resource_action.secrets[key].sensitive_output : azapi_resource_action.secrets[key].sensitive_output
  }
  subscription_id = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id).subscription_id
}
