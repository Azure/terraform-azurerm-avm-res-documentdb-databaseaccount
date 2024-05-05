variable "name" {
  type        = string
  nullable    = false
  description = <<DESCRIPTION
  Specifies the name of the CosmosDB Account. Changing this forces a new resource to be created.
  The name can contain only lowercase letters, numbers and the '-' character, must be between 3 and 44 characters long, and must not start or end with the character '-'.

  Example Inputs: cosmos-sharepoint-prod-westus-001
  See more: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftdocumentdb
  DESCRIPTION

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "The name variable must only contain letters, numbers, and hyphens."
  }

  validation {
    condition     = length(var.name) <= 44 && length(var.name) >= 3
    error_message = "The name variable must be between 3 and 44 characters long"
  }

  validation {
    condition     = substr(var.name, 0, 1) != "-" && substr(var.name, length(var.name) - 1, 1) != "-"
    error_message = "The name variable must not start or end with a hyphen."
  }
}

variable "resource_group_name" {
  type        = string
  nullable    = false
  description = <<DESCRIPTION
  The name of the resource group in which to create this resource. 
  Changing this forces a new resource to be created.
  Name must be less than 90 characters long and must only contain underscores, hyphens, periods, parentheses, letters, or digits.

  Example Inputs: rg-sharepoint-prod-westus-001
  See more: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftresources
  DESCRIPTION

  validation {
    condition     = length(var.resource_group_name) <= 90
    error_message = "The resource_group_name variable must be less than 90 characters long."
  }

  validation {
    condition     = can(regex("^[().a-zA-Z0-9_-]+$", var.resource_group_name))
    error_message = "The resource_group_name variable must only contain underscores, hyphens, periods, parentheses, letters, or digits."
  }
}

variable "location" {
  type        = string
  nullable    = false
  description = <<DESCRIPTION
  Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.
  
  Example Inputs: eastus
  See more in CLI: az account list-locations -o table --query "[].name"
  DESCRIPTION
}

variable "geo_locations" {
  type = set(object({
    location          = string
    failover_priority = number
    zone_redundant    = optional(bool, true)
  }))
  nullable    = false
  description = <<DESCRIPTION
  Specifies a geo_location resource, used to define where data should be replicated with the failover_priority 0 specifying the primary location.

  - `location`          - (Required) - The name of the Azure location where the CosmosDB Account is being created.
  - `failover_priority` - (Required) - The failover priority of the region. A failover priority of 0 indicates a write region.
  - `zone_redundant`    - (Optional) - Defaults to `true`. Whether or not the region is zone redundant.
  
  Example inputs:
  ```hcl
  geo_locations = [
    {
      location          = "eastus"
      failover_priority = 0
      zone_redundant    = true
    },
    {
      location          = "westus"
      failover_priority = 1
      zone_redundant    = true
    }
  ]
  ```
  DESCRIPTION
}