terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
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
  prefix = "less"
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
  location = "spaincentral"
  name     = "${module.naming.resource_group.name_unique}-${local.prefix}"
}

module "cosmos" {
  source = "../../"

  location            = azurerm_resource_group.example.location
  name                = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"
  resource_group_name = azurerm_resource_group.example.name
  capabilities = [
    {
      name = "EnableServerless"
    }
  ]
}
