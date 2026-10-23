mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

variables {
  location            = "northeurope"
  name                = "cosmos-unit-test"
  resource_group_name = "rg-unit-test"
  enable_telemetry    = false
}

run "account_role_assignment_passes_all_fields" {
  command = plan

  variables {
    role_assignments = {
      abac = {
        role_definition_id_or_name = "Cosmos DB Account Reader Role"
        principal_id               = "00000000-0000-0000-0000-000000000001"
        description                = "Account-scoped role assignment"
        principal_type             = "ServicePrincipal"
        condition                  = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEquals 'example'"
        condition_version          = "2.0"
      }
    }
  }

  assert {
    condition     = azurerm_role_assignment.this["Account|abac"].principal_type == "ServicePrincipal"
    error_message = "principal_type must be passed to azurerm_role_assignment."
  }

  assert {
    condition     = azurerm_role_assignment.this["Account|abac"].description == "Account-scoped role assignment"
    error_message = "description must be passed to azurerm_role_assignment."
  }

  assert {
    condition     = azurerm_role_assignment.this["Account|abac"].condition == "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEquals 'example'"
    error_message = "condition must be passed to azurerm_role_assignment."
  }

  assert {
    condition     = azurerm_role_assignment.this["Account|abac"].condition_version == "2.0"
    error_message = "condition_version must be passed to azurerm_role_assignment."
  }
}

run "private_endpoint_role_assignment_passes_all_fields" {
  command = plan

  variables {
    private_endpoints = {
      pe = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
        subresource_name   = "SQL"
        role_assignments = {
          abac = {
            role_definition_id_or_name = "Reader"
            principal_id               = "00000000-0000-0000-0000-000000000002"
            description                = "Private endpoint-scoped role assignment"
            principal_type             = "Group"
            condition                  = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEquals 'example'"
            condition_version          = "2.0"
          }
        }
      }
    }
  }

  assert {
    condition     = azurerm_role_assignment.this["PrivateEndpoint|abac"].principal_type == "Group"
    error_message = "principal_type must be passed to azurerm_role_assignment for private endpoint role assignments."
  }

  assert {
    condition     = azurerm_role_assignment.this["PrivateEndpoint|abac"].description == "Private endpoint-scoped role assignment"
    error_message = "description must be passed to azurerm_role_assignment for private endpoint role assignments."
  }

  assert {
    condition     = azurerm_role_assignment.this["PrivateEndpoint|abac"].condition == "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEquals 'example'"
    error_message = "condition must be passed to azurerm_role_assignment for private endpoint role assignments."
  }

  assert {
    condition     = azurerm_role_assignment.this["PrivateEndpoint|abac"].condition_version == "2.0"
    error_message = "condition_version must be passed to azurerm_role_assignment for private endpoint role assignments."
  }
}

run "invalid_principal_type_is_rejected" {
  command = plan

  variables {
    role_assignments = {
      bad = {
        role_definition_id_or_name = "Reader"
        principal_id               = "00000000-0000-0000-0000-000000000003"
        principal_type             = "ManagedIdentity"
      }
    }
  }

  expect_failures = [var.role_assignments]
}

run "condition_version_without_condition_is_rejected" {
  command = plan

  variables {
    role_assignments = {
      bad = {
        role_definition_id_or_name = "Reader"
        principal_id               = "00000000-0000-0000-0000-000000000004"
        condition_version          = "2.0"
      }
    }
  }

  expect_failures = [var.role_assignments]
}

run "invalid_private_endpoint_principal_type_is_rejected" {
  command = plan

  variables {
    private_endpoints = {
      pe = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
        subresource_name   = "SQL"
        role_assignments = {
          bad = {
            role_definition_id_or_name = "Reader"
            principal_id               = "00000000-0000-0000-0000-000000000005"
            principal_type             = "ManagedIdentity"
          }
        }
      }
    }
  }

  expect_failures = [var.private_endpoints]
}
