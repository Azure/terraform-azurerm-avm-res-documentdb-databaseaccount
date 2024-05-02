resource "azurerm_cosmosdb_account" "this" {
  name                  = var.name

  tags = var.tags
  location                   = var.location
  minimal_tls_version = var.minimum_tls_version
  resource_group_name        = var.resource_group_name
  local_authentication_disabled = var.local_auth_enabled
  public_network_access_enabled = var.public_network_access_enabled

  analytical_storage_enabled         = true
  access_key_metadata_writes_enabled = true
  automatic_failover_enabled         = true
  create_mode = "Default"
  free_tier_enabled = true
  ip_range_filter = ""
  is_virtual_network_filter_enabled = true
  key_vault_key_id = ""
  
  mongo_server_version = ""
  multiple_write_locations_enabled = true
  network_acl_bypass_for_azure_services = true
  partition_merge_enabled = true
  network_acl_bypass_ids = ""
  
  default_identity_type = join("=", ["UserAssignedIdentity", azurerm_user_assigned_identity.example.id])
  offer_type            = "Standard"
  kind                  = "MongoDB"

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level = "Strong"
  }

  geo_location {
    location          = "westus"
    failover_priority = 0
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.example.id]
  }

  backup {
    type = ""
  }

  capacity {
    total_throughput_limit = 1000
  }

  virtual_network_rule {
    
  }
}