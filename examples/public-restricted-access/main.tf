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

locals {
  prefix = "respub"
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
  location = module.regions.regions[random_integer.region_index.result].name
}

resource "azurerm_virtual_network" "example" {
  name = "${module.naming.virtual_network.name_unique}-${local.prefix}"

  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}

resource "azurerm_subnet" "example" {
  name = module.naming.subnet.name_unique

  address_prefixes     = ["10.0.0.0/24"]
  service_endpoints    = ["Microsoft.AzureCosmosDB"]
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
}

module "cosmos" {
  source = "../../"

  resource_group_name           = azurerm_resource_group.example.name
  location                      = azurerm_resource_group.example.location
  name                          = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"
  public_network_access_enabled = true
  geo_locations = [
    {
      failover_priority = 0
      location          = azurerm_resource_group.example.location
    }
  ]

  network_acl_bypass_for_azure_services = true
  ip_range_filter                       = ["168.125.123.255", "170.0.0.0/24"]
  virtual_network_rules = [
    {
      subnet_id = azurerm_subnet.example.id
    }
  ]
}
