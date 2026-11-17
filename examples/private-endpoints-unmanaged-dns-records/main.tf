terraform {
  required_version = ">= 1.16, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
  }
}

data "azapi_client_config" "current" {}

locals {
  prefix = "pe-umg"
}

module "naming" {
  source  = "Azure/avm-utl-naming/azure"
  version = "0.2.0"
}

resource "azapi_resource" "resource_group" {
  location = "spaincentral"
  name     = "${module.naming.resource_group.name_unique}-${local.prefix}"
  type     = "Microsoft.Resources/resourceGroups@2024-03-01"
}

resource "azapi_resource" "virtual_network" {
  location  = azapi_resource.resource_group.location
  name      = "${module.naming.virtual_network.name_unique}-${local.prefix}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.0.0.0/16"]
      }
      subnets = [
        {
          name = module.naming.subnet.name_unique
          properties = {
            addressPrefix = "10.0.0.0/24"
          }
        }
      ]
    }
  }
}

resource "azapi_resource" "private_dns_zone" {
  location  = "global"
  name      = "privatelink.documents.azure.com"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/privateDnsZones@2024-06-01"
}

resource "azapi_resource" "private_dns_zone_virtual_network_link" {
  location  = "global"
  name      = "vnet-link"
  parent_id = azapi_resource.private_dns_zone.id
  type      = "Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01"
  body = {
    properties = {
      registrationEnabled = false
      virtualNetwork = {
        id = azapi_resource.virtual_network.id
      }
    }
  }
}

resource "azapi_resource" "application_security_group" {
  location  = azapi_resource.resource_group.location
  name      = "tf-appsecuritygroup-${local.prefix}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/applicationSecurityGroups@2024-05-01"
}

module "cosmos" {
  source = "../../"

  location         = azapi_resource.resource_group.location
  name             = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"
  parent_id        = azapi_resource.resource_group.id
  enable_telemetry = var.enable_telemetry
  private_endpoints = {
    max = {
      name                            = "max"
      subresource_name                = "SQL"
      network_interface_name          = "max_nic1"
      private_dns_zone_group_name     = "max_dns_group"
      private_service_connection_name = "max_connection"
      subnet_resource_id              = "${azapi_resource.virtual_network.id}/subnets/${module.naming.subnet.name_unique}"
      private_dns_zone_resource_ids   = [azapi_resource.private_dns_zone.id]

      role_assignments = {
        key = {
          role_definition_id_or_name = "Contributor"
          description                = "This is a test role assignment"
          principal_id               = data.azapi_client_config.current.object_id
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
        asg1 = azapi_resource.application_security_group.id
      }
    }

    noDnsGroup = {
      name               = "no-dns-group"
      subresource_name   = "SQL"
      subnet_resource_id = "${azapi_resource.virtual_network.id}/subnets/${module.naming.subnet.name_unique}"
    }

    withDnsGroup = {
      name                          = "with-dns-group"
      subresource_name              = "SQL"
      subnet_resource_id            = "${azapi_resource.virtual_network.id}/subnets/${module.naming.subnet.name_unique}"
      private_dns_zone_resource_ids = [azapi_resource.private_dns_zone.id]
    }
  }
  private_endpoints_manage_dns_zone_group = false
  public_network_access_enabled           = false
}
