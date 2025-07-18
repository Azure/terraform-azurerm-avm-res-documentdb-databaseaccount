<!-- BEGIN_TF_DOCS -->
# Gremlin API example

This example shows the different possible configuration of the Gremlin API.

```hcl
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
  prefix = "gremlin"
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

  location                   = azurerm_resource_group.example.location
  name                       = "${module.naming.cosmosdb_account.name_unique}-${local.prefix}"
  resource_group_name        = azurerm_resource_group.example.name
  analytical_storage_enabled = true
  capabilities = [{
    name = "EnableGremlin"
  }]
  gremlin_databases = {
    empty_database = {
      name       = "empty_database"
      throughput = 400
    }

    database_autoscale_throughput = {
      name = "database_autoscale_throughput"

      autoscale_settings = {
        max_throughput = 4000
      }
    }

    database_with_fixed_throughput = {
      name       = "database_with_fixed_throughput"
      throughput = 400
    }

    database_with_graphs = {
      name       = "database_with_graphs"
      throughput = 400

      graphs = {
        "graph_fixed_throughput" = {
          name               = "graph_fixed_throughput"
          partition_key_path = "/partitionKey"
          throughput         = 400
        }

        "graph_autoscale" = {
          name               = "graph_autoscale"
          partition_key_path = "/partitionKey"

          autoscale_settings = {
            max_throughput = 4000
          }
        }

        "graph_with_ttl" = {
          name               = "graph_with_ttl"
          partition_key_path = "/partitionKey"
          default_ttl        = 3600
        }

        "graph_with_analytical_storage" = {
          name                   = "graph_with_analytical_storage"
          partition_key_path     = "/partitionKey"
          analytical_storage_ttl = -1
        }

        "graph_with_partition_key_v2" = {
          name                  = "graph_with_partition_key_v2"
          partition_key_path    = "/largePartitionKey"
          partition_key_version = "2"
        }

        "graph_with_index_policy" = {
          name               = "graph_with_index_policy"
          partition_key_path = "/partitionKey"

          index_policy = {
            automatic      = true
            indexing_mode  = "consistent"
            included_paths = ["/", "/included/*"]
            excluded_paths = ["/excluded/*"]

            composite_index = [
              {
                index = [
                  {
                    path  = "/name"
                    order = "Ascending"
                  },
                  {
                    path  = "/age"
                    order = "Descending"
                  }
                ]
              }
            ]

            spatial_index = [
              {
                path = "/location/*"
              }
            ]
          }
        }

        "graph_with_conflict_resolution" = {
          name               = "graph_with_conflict_resolution"
          partition_key_path = "/partitionKey"

          conflict_resolution_policy = {
            mode                     = "LastWriterWins"
            conflict_resolution_path = "/_ts"
          }
        }

        "graph_with_unique_key" = {
          name               = "graph_with_unique_key"
          partition_key_path = "/partitionKey"

          unique_key = {
            paths = ["/uniqueField"]
          }
        }
      }
    }
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.6)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_cosmos"></a> [cosmos](#module\_cosmos)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: >= 0.3.0

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: >= 0.3.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->