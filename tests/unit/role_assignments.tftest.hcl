mock_provider "azapi" {
  alias = "mocked"

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-unit-test"
      output = {
        document_endpoint = "https://cosmos-unit-test.documents.azure.com:443/"
        read_endpoints    = []
        write_endpoints   = []
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
        locations = [{ name = "northeurope", display_name = "North Europe" }]
      }
    }
  }

  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [
          {
            id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/fbdf93bf-df7d-467e-a4d2-9458aa1360c8"
            role_name = "Cosmos DB Account Reader Role"
          },
          {
            id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
            role_name = "Reader"
          },
        ]
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

run "account_role_assignment_passes_all_fields" {
  command = apply
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  variables {
    role_assignments = {
      abac = {
        role_definition_id_or_name = "cosmos db account reader role"
        principal_id               = "00000000-0000-0000-0000-000000000001"
        description                = "Account-scoped role assignment"
        principal_type             = "ServicePrincipal"
        condition                  = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEquals 'example'"
        condition_version          = "2.0"
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignments["Account|abac"].parent_id == azapi_resource.this.id && azapi_resource.role_assignments["Account|abac"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/fbdf93bf-df7d-467e-a4d2-9458aa1360c8"
    error_message = "A role name must be matched ignoring case, as the AzureRM provider matched it, and assigned on the account."
  }

  assert {
    condition     = azapi_resource.role_assignments["Account|abac"].body.properties.principalType == "ServicePrincipal" && azapi_resource.role_assignments["Account|abac"].body.properties.description == "Account-scoped role assignment"
    error_message = "principal_type and description must be passed to the role assignment."
  }

  assert {
    condition     = azapi_resource.role_assignments["Account|abac"].body.properties.condition == "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEquals 'example'" && azapi_resource.role_assignments["Account|abac"].body.properties.conditionVersion == "2.0"
    error_message = "condition and condition_version must be passed to the role assignment."
  }
}

run "private_endpoint_role_assignment_passes_all_fields" {
  command = apply
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  variables {
    private_endpoints = {
      pe = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit-test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
        subresource_name   = "SQL"
        role_assignments = {
          abac = {
            name                             = "8f6b3c6e-4f1e-4b5a-9d55-0c0e0e9d1a11"
            role_definition_id_or_name       = "Reader"
            principal_id                     = "00000000-0000-0000-0000-000000000002"
            description                      = "Private endpoint-scoped role assignment"
            skip_service_principal_aad_check = true
            condition                        = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEquals 'example'"
            condition_version                = "2.0"
          }
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignments["PrivateEndpoint|abac"].parent_id == azapi_resource.private_endpoints["pe"].id && azapi_resource.role_assignments["PrivateEndpoint|abac"].name == "8f6b3c6e-4f1e-4b5a-9d55-0c0e0e9d1a11"
    error_message = "A private endpoint role assignment must be assigned on the private endpoint, with the name given."
  }

  assert {
    condition     = azapi_resource.role_assignments["PrivateEndpoint|abac"].body.properties.principalType == "ServicePrincipal"
    error_message = "skip_service_principal_aad_check must send the ServicePrincipal principal type, as the AzureRM provider did."
  }

  assert {
    condition     = azapi_resource.role_assignments["PrivateEndpoint|abac"].body.properties.description == "Private endpoint-scoped role assignment" && azapi_resource.role_assignments["PrivateEndpoint|abac"].body.properties.conditionVersion == "2.0"
    error_message = "description and condition_version must be passed to the private endpoint role assignment."
  }
}

run "unknown_role_name_is_rejected" {
  command = plan
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

  variables {
    role_assignments = {
      bad = {
        role_definition_id_or_name = "Not A Role"
        principal_id               = "00000000-0000-0000-0000-000000000006"
      }
    }
  }

  expect_failures = [azapi_resource.role_assignments]
}

run "invalid_principal_type_is_rejected" {
  command = plan
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

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
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

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
  providers = {
    azapi  = azapi.mocked
    random = random.mocked
    time   = time.mocked
  }

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
