terraform {
  required_version = "~> 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.71"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_client_config" "current" {}

locals {
  prefix = "max"
  skus   = ["Basic", "Standard", "Premium"]
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.3.0"

  recommended_regions_only = true
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

resource "azurerm_resource_group" "example" {
  name     = "${module.naming.resource_group.name_unique}-${local.prefix}"
  location = "westeurope" # This test case in Premium SKU is not supported in some of the recommended regions. Pinned to an specific one to make the test more reliable. #module.regions.regions[random_integer.region_index.result].name
}

module "servicebus" {
  source = "../../"

  for_each = toset(local.skus)

  sku                                     = each.value
  resource_group_name                     = azurerm_resource_group.example.name
  location                                = azurerm_resource_group.example.location
  name                                    = "${module.naming.servicebus_namespace.name_unique}-${each.value}-${local.prefix}"
  capacity                                = 2
  local_auth_enabled                      = true
  minimum_tls_version                     = "1.2"
  public_network_access_enabled           = true
  premium_messaging_partitions            = 2
  zone_redundant                          = true
  enable_telemetry                        = true
  private_endpoints_manage_dns_zone_group = true

  authorization_rules = {
    testRule = {
      send   = true
      listen = true
      manage = true
    }
  }

  tags = {
    environment = "testing"
    department  = "engineering"
  }

  role_assignments = {
    key = {
      skip_service_principal_aad_check = false
      role_definition_id_or_name       = "Contributor"
      description                      = "This is a test role assignment"
      principal_id                     = data.azurerm_client_config.current.object_id
    }
  }

  lock = {
    kind = "CanNotDelete"
    name = "Testing name CanNotDelete"
  }
}
