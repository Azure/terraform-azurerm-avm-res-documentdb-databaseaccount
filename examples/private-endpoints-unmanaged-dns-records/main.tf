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
  prefix = "pe-umg"
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
  location = "northeurope"
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
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
}

resource "azurerm_private_dns_zone" "example" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_links" {
  name = "vnet-link"

  resource_group_name   = azurerm_resource_group.example.name
  virtual_network_id    = azurerm_virtual_network.example.id
  private_dns_zone_name = azurerm_private_dns_zone.example.name
}

resource "azurerm_application_security_group" "example" {
  name = "tf-appsecuritygroup-${local.prefix}"

  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}

module "cosmos" {
  source = "../../"

  resource_group_name                     = azurerm_resource_group.example.name
  location                                = azurerm_resource_group.example.location
  name                                    = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"
  public_network_access_enabled           = false
  private_endpoints_manage_dns_zone_group = false
  private_endpoints = {
    max = {
      name                            = "max"
      subresource_name                = "SQL"
      network_interface_name          = "max_nic1"
      private_dns_zone_group_name     = "max_dns_group"
      private_service_connection_name = "max_connection"
      subnet_resource_id              = azurerm_subnet.example.id
      private_dns_zone_resource_ids   = [azurerm_private_dns_zone.example.id]

      role_assignments = {
        key = {
          role_definition_id_or_name = "Contributor"
          description                = "This is a test role assignment"
          principal_id               = data.azurerm_client_config.current.object_id
        }
      }

      lock = {
        kind = "CanNotDelete"
        name = "Testing name CanNotDelete"
      }

      tags = {
        environment = "testing"
        department  = "engineering"
      }

      application_security_group_associations = {
        asg1 = azurerm_application_security_group.example.id
      }
    }

    noDnsGroup = {
      name               = "no-dns-group"
      subresource_name   = "SQL"
      subnet_resource_id = azurerm_subnet.example.id
    }

    withDnsGroup = {
      name                          = "with-dns-group"
      subresource_name              = "SQL"
      subnet_resource_id            = azurerm_subnet.example.id
      private_dns_zone_resource_ids = [azurerm_private_dns_zone.example.id]
    }
  }
}
