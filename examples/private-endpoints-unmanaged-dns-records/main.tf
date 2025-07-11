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
  location = "spaincentral"
  name     = "${module.naming.resource_group.name_unique}-${local.prefix}"
}

resource "azurerm_virtual_network" "example" {
  location            = azurerm_resource_group.example.location
  name                = "${module.naming.virtual_network.name_unique}-${local.prefix}"
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "example" {
  address_prefixes     = ["10.0.0.0/24"]
  name                 = module.naming.subnet.name_unique
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
}

resource "azurerm_private_dns_zone" "example" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_links" {
  name                  = "vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  resource_group_name   = azurerm_resource_group.example.name
  virtual_network_id    = azurerm_virtual_network.example.id
}

resource "azurerm_application_security_group" "example" {
  location            = azurerm_resource_group.example.location
  name                = "tf-appsecuritygroup-${local.prefix}"
  resource_group_name = azurerm_resource_group.example.name
}

module "cosmos" {
  source = "../../"

  location            = azurerm_resource_group.example.location
  name                = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"
  resource_group_name = azurerm_resource_group.example.name
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
  private_endpoints_manage_dns_zone_group = false
  public_network_access_enabled           = false
}
