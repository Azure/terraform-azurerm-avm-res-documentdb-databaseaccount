terraform {
  required_version = ">= 1.16, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
  }
}

locals {
  prefix = "respub"
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
            serviceEndpoints = [
              {
                service = "Microsoft.AzureCosmosDB"
              }
            ]
          }
        }
      ]
    }
  }
}

module "cosmos" {
  source = "../../"

  location         = azapi_resource.resource_group.location
  name             = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"
  parent_id        = azapi_resource.resource_group.id
  enable_telemetry = var.enable_telemetry
  ip_range_filter = [
    "168.125.123.255",
    "170.0.0.0/24",
    "0.0.0.0",                                                                      #Accept connections from within public Azure datacenters. https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-configure-firewall#allow-requests-from-the-azure-portal
    "104.42.195.92", "40.76.54.131", "52.176.6.30", "52.169.50.45", "52.187.184.26" #Allow access from the Azure portal. https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-configure-firewall#allow-requests-from-global-azure-datacenters-or-other-sources-within-azure
  ]
  network_acl_bypass_for_azure_services = true
  public_network_access_enabled         = true
  virtual_network_rules = [
    {
      subnet_id = "${azapi_resource.virtual_network.id}/subnets/${module.naming.subnet.name_unique}"
    }
  ]
}
