<!-- BEGIN_TF_DOCS -->
# Topics example

This example deploys the module with multiple combinations of topics.

```hcl
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
  prefix = "topics"
  skus   = ["Standard", "Premium"]
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

module "servicebus" {
  source = "../../"

  for_each = toset(local.skus)

  sku                 = each.value
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  name                = "${module.naming.servicebus_namespace.name_unique}-${each.value}-${local.prefix}"

  topics = {
    forwardTopic = {
    }

    enableExpressTopic = {
      enable_express               = true
      requires_duplicate_detection = false
    }

    testTopic = {
      auto_delete_on_idle                     = "P7D"
      default_message_ttl                     = "PT5M"
      duplicate_detection_history_time_window = "PT5M"
      enable_batched_operations               = true
      enable_express                          = false
      enable_partitioning                     = true
      requires_duplicate_detection            = null
      max_message_size_in_kilobytes           = 1024
      max_size_in_megabytes                   = 1024
      status                                  = "Active"
      support_ordering                        = true

      role_assignments = {
        key = {
          skip_service_principal_aad_check = false
          role_definition_id_or_name       = "Contributor"
          description                      = "This is a test role assignment"
          principal_id                     = data.azurerm_client_config.current.object_id
        }
      }

      subscriptions = {
        testSubscription = {
          dead_lettering_on_filter_evaluation_error = true
          dead_lettering_on_message_expiration      = true
          default_message_ttl                       = "PT5M"
          enable_batched_operations                 = true
          lock_duration                             = "PT1M"
          max_delivery_count                        = 100
          status                                    = "Active"
          auto_delete_on_idle                       = "P7D"
          requires_session                          = true
        }

        fromForwardSubscription = {
          requires_session                  = false
          forward_to                        = "forwardTopic"
          forward_dead_lettered_messages_to = "forwardTopic"
        }
      }

      authorization_rules = {
        testRule = {
          send   = true
          listen = true
          manage = true
        }
      }
    }
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.5)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.71)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.6)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.71)

- <a name="provider_random"></a> [random](#provider\_random) (~> 3.6)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: >= 0.3.0

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: >= 0.3.0

### <a name="module_servicebus"></a> [servicebus](#module\_servicebus)

Source: ../../

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->