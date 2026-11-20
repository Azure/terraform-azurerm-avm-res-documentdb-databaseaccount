variable "location" {
  type        = string
  description = <<DESCRIPTION
  Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.

  Example Inputs: eastus
  See more in CLI: az account list-locations -o table --query "[].name"
  DESCRIPTION
  nullable    = false
}

variable "name" {
  type        = string
  description = <<DESCRIPTION
  Specifies the name of the CosmosDB Account. Changing this forces a new resource to be created.
  The name can contain only lowercase letters, numbers and the '-' character, must be between 3 and 44 characters long, and must not start or end with the character '-'.

  Example Inputs: cosmos-sharepoint-prod-westus-001
  See more: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftdocumentdb
  DESCRIPTION
  nullable    = false

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

variable "parent_id" {
  type        = string
  description = "(Required) The resource ID of the resource group in which to create the Cosmos DB account, for example `/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg`. Changing this forces a new resource to be created."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "`parent_id` must be a valid Azure resource group resource ID."
  }
}

variable "avm_managed_migration_enabled" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
(Optional) Set to `true` for the apply that upgrades from version 0.12.x or earlier. The module then reads the account's keys and connection strings during plan, so that resources that use them are not changed, and adopts the private DNS zone groups that earlier versions created inside the private endpoints, instead of failing with `Resource already exists`.

Leave this `false` on a new deployment. An import cannot adopt a zone group that does not exist yet, so enabling it before the zone groups exist fails at plan time.

Terraform skips an import whose target is already in state, so the flag is a no-op for the zone groups it adopted. Remove it after the upgrade, before adding private endpoints with new zone groups or a `ReadOnly` lock, which blocks reading the keys.
DESCRIPTION
  nullable    = false
}
