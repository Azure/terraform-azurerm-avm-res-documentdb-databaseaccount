mock_provider "azapi" {
  alias = "mocked"

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-unit-test"
      output = {
        document_endpoint = "https://cosmos-unit-test.documents.azure.com:443/"
        read_endpoints    = ["https://cosmos-unit-test-northeurope.documents.azure.com:443/"]
        write_endpoints   = ["https://cosmos-unit-test-northeurope.documents.azure.com:443/"]
      }
    }
  }

  mock_resource "azapi_resource_action" {
    defaults = {
      sensitive_output = {
        connectionStrings = [
          {
            connectionString = "AccountEndpoint=https://cosmos-unit-test.documents.azure.com:443/;AccountKey=created-primary;"
            description      = "Primary SQL Connection String"
          },
          {
            connectionString = "AccountEndpoint=https://cosmos-unit-test.documents.azure.com:443/;AccountKey=created-readonly;"
            description      = "Primary Read-Only SQL Connection String"
          },
        ]
        primaryMasterKey           = "created-primary"
        primaryReadonlyMasterKey   = "created-readonly"
        secondaryMasterKey         = "created-secondary"
        secondaryReadonlyMasterKey = "created-secondary-readonly"
      }
    }
  }

  mock_data "azapi_resource" {
    defaults = {
      exists = false
      output = {
        document_endpoint = "https://cosmos-unit-test.documents.azure.com:443/"
        location          = "North Europe"
      }
    }
  }

  mock_data "azapi_resource_action" {
    defaults = {
      output = {
        locations = [
          { name = "northeurope", display_name = "North Europe" },
          { name = "westeurope", display_name = "West Europe" },
        ]
      }
      sensitive_output = {
        connectionStrings = [
          {
            connectionString = "mongodb://cosmos-unit-test:existing-primary@cosmos-unit-test.mongo.cosmos.azure.com:10255/"
            description      = "Primary MongoDB Connection String"
          },
        ]
        primaryMasterKey           = "existing-primary"
        primaryReadonlyMasterKey   = "existing-readonly"
        secondaryMasterKey         = "existing-secondary"
        secondaryReadonlyMasterKey = "existing-secondary-readonly"
      }
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "random" {
  alias = "mocked"
}

mock_provider "time" {
  alias = "mocked"
}

variables {
  enable_telemetry = false
  location         = "northeurope"
  name             = "cosmos-unit-test"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test"
}

run "account_defaults_match_earlier_versions" {
  command = apply
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  assert {
    condition     = azapi_resource.this.parent_id == var.parent_id && azapi_resource.this.type == "Microsoft.DocumentDB/databaseAccounts@2026-03-15" && azapi_resource.this.body.kind == "GlobalDocumentDB"
    error_message = "The account must be a GlobalDocumentDB account created in the parent resource group."
  }
  assert {
    condition = azapi_resource.this.body.properties.consistencyPolicy == {
      defaultConsistencyLevel = "BoundedStaleness"
      maxIntervalInSeconds    = 5
      maxStalenessPrefix      = 100
    }
    error_message = "The consistency policy must default as before."
  }
  assert {
    condition     = azapi_resource.this.body.properties.backupPolicy.type == "Continuous" && azapi_resource.this.body.properties.backupPolicy.continuousModeProperties.tier == "Continuous30Days" && !contains(keys(azapi_resource.this.body.properties.backupPolicy), "periodicModeProperties")
    error_message = "The backup policy must default to Continuous30Days, without periodic settings."
  }
  assert {
    condition     = azapi_resource.this.body.properties.defaultIdentity == "FirstPartyIdentity" && azapi_resource.this.body.properties.disableLocalAuth && azapi_resource.this.body.properties.publicNetworkAccess == "Disabled" && azapi_resource.this.body.properties.networkAclBypass == "None"
    error_message = "The identity, authentication and network defaults must be sent as the AzureRM provider sent them."
  }
  assert {
    condition     = length(azapi_resource.this.body.properties.ipRules) == 0 && length(azapi_resource.this.body.properties.virtualNetworkRules) == 0 && length(azapi_resource.this.body.properties.capabilities) == 0 && !azapi_resource.this.body.properties.isVirtualNetworkFilterEnabled
    error_message = "Empty network rules and capabilities must be sent as empty lists."
  }
  assert {
    condition     = azapi_resource.this.body.properties.locations == [{ failoverPriority = 0, isZoneRedundant = true, locationName = "North Europe" }]
    error_message = "The default region must be sent with the display name Azure returns."
  }
  assert {
    condition     = length(azapi_resource.this.replace_triggers_external_values.capabilities) == 0 && azapi_resource.this.replace_triggers_external_values.free_tier_enabled == false && azapi_resource.this.replace_triggers_external_values.key_vault_key_url == null && azapi_resource.this.replace_triggers_external_values.kind == "GlobalDocumentDB"
    error_message = "Only the settings that the AzureRM provider replaced the account for may trigger a replacement."
  }
  assert {
    condition     = toset([for action in azapi_resource_action.secrets : action.action]) == toset(["listConnectionStrings", "listKeys", "readonlykeys"]) && length(data.azapi_resource_action.secrets) == 0
    error_message = "The keys and connection strings must be read when the account is created, and not during later plans, which a ReadOnly lock would block."
  }
  assert {
    condition     = length(azapi_resource.locks) == 0 && length(azapi_resource.role_assignments) == 0 && length(azapi_resource.diagnostic_settings) == 0 && length(azapi_resource.private_endpoints) == 0 && length(time_sleep.lock_removal) == 0
    error_message = "Optional interfaces must be absent by default."
  }
  assert {
    condition     = output.resource_group_name == "rg-unit-test" && output.location == "northeurope" && output.endpoint == "https://cosmos-unit-test.documents.azure.com:443/"
    error_message = "The outputs must keep the values earlier versions returned."
  }
  assert {
    condition     = nonsensitive(output.cosmosdb_keys.primary_key) == "created-primary" && nonsensitive(output.cosmosdb_keys.secondary_readonly_key) == "created-secondary-readonly"
    error_message = "The keys must come from the account created."
  }
  assert {
    condition     = nonsensitive(output.cosmosdb_sql_connection_strings.primary_readonly_sql_connection_string) == "AccountEndpoint=https://cosmos-unit-test.documents.azure.com:443/;AccountKey=created-readonly;" && nonsensitive(output.cosmosdb_sql_connection_strings.secondary_sql_connection_string) == null && nonsensitive(output.cosmosdb_mongodb_connection_strings.primary_mongodb_connection_string) == null
    error_message = "Connection strings must be matched by description, and missing ones must be null, as before."
  }
}

run "secrets_are_read_during_plan_while_migrating" {
  command = apply
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  variables {
    avm_managed_migration_enabled = true
  }

  assert {
    condition     = length(data.azapi_resource_action.secrets) == 3 && nonsensitive(output.cosmosdb_keys.primary_key) == "existing-primary"
    error_message = "While upgrading, the keys must be read during plan from the existing account, so that resources that use them are not changed."
  }
  assert {
    condition     = nonsensitive(output.cosmosdb_mongodb_connection_strings.primary_mongodb_connection_string) == "mongodb://cosmos-unit-test:existing-primary@cosmos-unit-test.mongo.cosmos.azure.com:10255/"
    error_message = "While upgrading, the connection strings must come from the existing account."
  }
}

run "existing_account_endpoint_is_known_during_plan" {
  command = plan
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  override_data {
    target = data.azapi_resource.account
    values = {
      exists = true
      output = {
        document_endpoint = "https://cosmos-unit-test.documents.azure.com:443/"
        location          = "North Europe"
      }
    }
  }

  assert {
    condition     = output.endpoint == "https://cosmos-unit-test.documents.azure.com:443/"
    error_message = "The endpoint of an existing account must be known during plan."
  }
}

run "account_settings_reach_the_request" {
  command = apply
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  variables {
    backup = {
      type                = "Periodic"
      interval_in_minutes = 120
      retention_in_hours  = 24
      storage_redundancy  = "Local"
    }
    capabilities = [
      { name = "DeleteAllItemsByPartitionKey" },
      { name = "EnableNoSQLVectorSearch" },
    ]
    consistency_policy = {
      consistency_level = "Session"
    }
    cors_rule = {
      allowed_headers = ["x-ms-meta-*"]
      allowed_methods = ["GET", "POST"]
      allowed_origins = ["https://contoso.com"]
      exposed_headers = ["x-ms-meta-*"]
    }
    customer_managed_key = {
      key_name              = "cmk"
      key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.KeyVault/vaults/kv-unit-test"
      user_assigned_identity = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami"
      }
    }
    geo_locations = [
      { location = "northeurope", failover_priority = 0 },
      { location = "West Europe", failover_priority = 1, zone_redundant = false },
    ]
    ip_range_filter = ["10.0.0.0/16", "203.0.113.4"]
    managed_identities = {
      system_assigned            = true
      user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami"]
    }
    multiple_write_locations_enabled = true
    tags                             = { environment = "test" }
    virtual_network_rules = [
      { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" },
    ]
  }

  assert {
    condition     = { for location in azapi_resource.this.body.properties.locations : location.locationName => [location.failoverPriority, location.isZoneRedundant] } == { "North Europe" = [0, true], "West Europe" = [1, false] }
    error_message = "Regions must be sent by display name, with their priority and zone redundancy."
  }
  assert {
    condition     = azapi_resource.this.body.properties.backupPolicy.periodicModeProperties == { backupIntervalInMinutes = 120, backupRetentionIntervalInHours = 24, backupStorageRedundancy = "Local" } && !contains(keys(azapi_resource.this.body.properties.backupPolicy), "continuousModeProperties") && azapi_resource.this.body.properties.enableMultipleWriteLocations
    error_message = "Periodic backups must send their settings, and allow multiple write regions."
  }
  assert {
    condition     = azapi_resource.this.body.properties.consistencyPolicy.maxIntervalInSeconds == 5 && azapi_resource.this.body.properties.consistencyPolicy.maxStalenessPrefix == 100
    error_message = "Staleness settings must be sent with their defaults unless the consistency is BoundedStaleness, as before."
  }
  assert {
    condition     = length(azapi_resource.this.body.properties.cors) == 1 && azapi_resource.this.body.properties.cors[0].allowedMethods == "GET,POST" && azapi_resource.this.body.properties.cors[0].allowedOrigins == "https://contoso.com" && azapi_resource.this.body.properties.cors[0].maxAgeInSeconds == null
    error_message = "CORS values must be sent comma-separated, without a zero max age."
  }
  assert {
    condition     = azapi_resource.this.body.properties.keyVaultKeyUri == "https://kv-unit-test.vault.azure.net/keys/cmk" && azapi_resource.this.body.properties.defaultIdentity == "UserAssignedIdentity=${var.customer_managed_key.user_assigned_identity.resource_id}"
    error_message = "The customer-managed key must be sent versionless, with its identity as the default identity."
  }
  assert {
    condition     = azapi_resource.this.identity[0].type == "SystemAssigned, UserAssigned" && length(azapi_resource.this.identity[0].identity_ids) == 1
    error_message = "Both identity types must be set."
  }
  assert {
    condition     = azapi_resource.this.body.properties.ipRules == [{ ipAddressOrRange = "10.0.0.0/16" }, { ipAddressOrRange = "203.0.113.4" }] && azapi_resource.this.body.properties.isVirtualNetworkFilterEnabled && azapi_resource.this.body.properties.virtualNetworkRules[0].ignoreMissingVNetServiceEndpoint == false
    error_message = "IP ranges must be sent, and virtual network rules must enable the virtual network filter."
  }
  assert {
    condition     = azapi_resource.this.replace_triggers_external_values.capabilities == tolist(["enablenosqlvectorsearch"]) && azapi_resource.this.replace_triggers_external_values.key_vault_key_url == "https://kv-unit-test.vault.azure.net/keys/cmk"
    error_message = "Capabilities that Azure can add in place, such as DeleteAllItemsByPartitionKey, must not replace the account."
  }
  assert {
    condition     = azapi_resource.this.tags["environment"] == "test" && output.key_vault_key_id == "https://kv-unit-test.vault.azure.net/keys/cmk"
    error_message = "Tags and the key output must be set."
  }
}

run "lock_is_created_last_with_the_notes_of_earlier_versions" {
  command = apply
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  variables {
    lock = {
      kind = "CanNotDelete"
    }
    private_endpoints = {
      pe = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
        subresource_name   = "Sql"
        lock = {
          kind  = "ReadOnly"
          notes = "Owned by the platform team."
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.locks["Account"].name == "lock-CanNotDelete" && azapi_resource.locks["Account"].body.properties == { level = "CanNotDelete", notes = "Cannot delete the resource or its child resources." }
    error_message = "The account lock must keep the name and notes of earlier versions."
  }
  assert {
    condition     = azapi_resource.locks["PrivateEndpoint|pe"].body.properties == { level = "ReadOnly", notes = "Owned by the platform team." }
    error_message = "A private endpoint lock must use its own kind and notes."
  }
  assert {
    condition     = length(time_sleep.lock_removal) == 2
    error_message = "Each lock must wait before the resources under it are destroyed."
  }
}

run "private_endpoints_match_earlier_versions" {
  command = apply
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  variables {
    tags = { environment = "test" }
    private_endpoints = {
      pe = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
        subresource_name              = "Sql"
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Network/privateDnsZones/privatelink.documents.azure.com"]
        resource_group_name           = "rg-network"
        application_security_group_associations = {
          asg = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Network/applicationSecurityGroups/asg"
        }
        ip_configurations = {
          ip = {
            name               = "ipconfig"
            private_ip_address = "10.0.0.10"
          }
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.private_endpoints["pe"].name == "pep-cosmos-unit-test" && azapi_resource.private_endpoints["pe"].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network" && azapi_resource.private_endpoints["pe"].tags["environment"] == "test"
    error_message = "The private endpoint must keep the default name, resource group and inherited tags of earlier versions."
  }
  assert {
    condition     = azapi_resource.private_endpoints["pe"].body.properties.privateLinkServiceConnections[0].name == "pse-pe" && azapi_resource.private_endpoints["pe"].body.properties.privateLinkServiceConnections[0].properties.groupIds == ["Sql"]
    error_message = "The private service connection must keep its default name."
  }
  assert {
    condition     = azapi_resource.private_endpoints["pe"].body.properties.ipConfigurations == [{ name = "ipconfig", properties = { groupId = "Sql", memberName = "Sql", privateIPAddress = "10.0.0.10" } }]
    error_message = "IP configurations must default the member name to the sub-resource, as before."
  }
  assert {
    condition     = length(azapi_resource.private_endpoints["pe"].body.properties.applicationSecurityGroups) == 1 && azapi_resource.private_dns_zone_groups["pe"].name == "default"
    error_message = "Application security groups must be set on the private endpoint, and the zone group must keep its name."
  }
  assert {
    condition     = output.resource_private_endpoints_application_security_group_association == ["${azapi_resource.private_endpoints["pe"].id}|${var.private_endpoints.pe.application_security_group_associations.asg}"]
    error_message = "The association output must keep the form of the AzureRM association IDs."
  }
}

run "private_endpoint_without_subresource_name_is_rejected" {
  command = plan
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  variables {
    private_endpoints = {
      pe = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
      }
    }
  }

  expect_failures = [var.private_endpoints]
}
