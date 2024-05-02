variable "name" {
  type        = string
  nullable    = false
  description = <<DESCRIPTION
  Specifies the name of the ServiceBus Namespace resource. 
  Changing this forces a new resource to be created. 
  Name must only contain letters, numbers, and hyphens and be between 6 and 50 characteres long. Also, it must not start or end with a hyphen.

  Example Inputs: sb-sharepoint-prod-westus-001
  See more: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftservicebus
  DESCRIPTION

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.name))
    error_message = "The name variable must only contain letters, numbers, and hyphens."
  }

  validation {
    condition     = length(var.name) <= 50 && length(var.name) >= 6
    error_message = "The name variable must be between 6 and 50 characters long"
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
  Azure region where the resource should be deployed.
  If null, the location will be inferred from the resource group location.
  Changing this forces a new resource to be created.
  
  Example Inputs: eastus
  See more in CLI: az account list-locations -o table --query "[].name"
  DESCRIPTION
}

variable "sku" {
  type        = string
  nullable    = false
  default     = "Standard"
  description = <<DESCRIPTION
  Defaults to `Standard`. Defines which tier to use. Options are Basic, Standard or Premium. 
  Please note that setting this field to Premium will force the creation of a new resource.
  DESCRIPTION

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "The sku variable must be either Basic, Standard, or Premium."
  }
}

variable "capacity" {
  type        = number
  default     = null
  description = <<DESCRIPTION
  Always set to `0` for Standard and Basic. Defaults to `1` for Premium. Specifies the capacity. 
  When sku is Premium, capacity can be 1, 2, 4, 8 or 16.
  DESCRIPTION

  validation {
    condition     = var.capacity == null || can(index([1, 2, 4, 8, 16], var.capacity))
    error_message = "The capacity variable must be 1, 2, 4, 8, or 16 when sku is Premium."
  }
}

variable "premium_messaging_partitions" {
  type        = number
  default     = null
  description = <<DESCRIPTION
  Always set to `0` for Standard and Basic. Defaults to `1` for Premium. Specifies the number of messaging partitions. 
  Possible values when Premium are 1, 2, and 4. Changing this forces a new resource to be created.
  DESCRIPTION

  validation {
    condition     = var.premium_messaging_partitions == null || can(index([1, 2, 4], var.premium_messaging_partitions))
    error_message = "The premium_messaging_partitions variable must be 1, 2, or 4 when sku is Premium."
  }
}

variable "zone_redundant" {
  type        = bool
  default     = null
  description = <<DESCRIPTION
  Always set to `false` for Standard and Basic. Defaults to `true` for Premium. Whether or not this resource is zone redundant. 
  Changing this forces a new resource to be created.
  DESCRIPTION
}

variable "local_auth_enabled" {
  type        = bool
  nullable    = false
  default     = true
  description = "Defaults to `true`. Whether or not SAS authentication is enabled for the Service Bus namespace."
}

variable "public_network_access_enabled" {
  type        = bool
  nullable    = false
  default     = true
  description = "Defaults to `true`. Is public network access enabled for the Service Bus Namespace?"
}

variable "minimum_tls_version" {
  type        = string
  nullable    = false
  default     = "1.2"
  description = "Defaults to `1.2`. The minimum supported TLS version for this Service Bus Namespace. Valid values are: 1.0, 1.1 and 1.2."

  validation {
    condition     = var.minimum_tls_version == null || can(index(["1.0", "1.1", "1.2"], var.minimum_tls_version))
    error_message = "The minimum_tls_version variable must be 1.0, 1.1 or 1.2."
  }
}

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
  Defaults to `{}`. Controls the Managed Identity configuration on this resource. The following properties can be specified:

  - `system_assigned`            - (Optional) - Defaults to `false`. Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) - Defaults to `[]`. Specifies a set of User Assigned Managed Identity resource IDs to be assigned to this resource.

  Example Inputs:
  ```hcl
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [
      "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{managedIdentityName}"
    ]
  }
  ```
  DESCRIPTION

  validation {
    condition = alltrue([
      for mi_id in var.managed_identities.user_assigned_resource_ids :
      can(regex("^/subscriptions/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/resourceGroups/.+/providers/Microsoft.ManagedIdentity/userAssignedIdentities/.+$", mi_id))
    ])
    error_message = "Managed identity resource IDs must be in the format /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{managedIdentityName}"
  }
}

variable "authorization_rules" {
  type = map(object({
    name   = optional(string, null)
    send   = optional(bool, false)
    listen = optional(bool, false)
    manage = optional(bool, false)
  }))
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
  Defaults to `{}`. Manages a ServiceBus Namespace authorization Rule within a ServiceBus.

  - `name`   - (Optional) - Defaults to `null`. Specifies the name of the ServiceBus Namespace Authorization Rule resource. Changing this forces a new resource to be created. If it is null it will use the map key as the name.
  - `send`   - (Optional) - Always set to `true` when manage is `true` if not it will default to `false`. Does this Authorization Rule have Listen permissions to the ServiceBus Namespace?
  - `listen` - (Optional) - Always set to `true` when manage is `true` if not it will default to `false`. Does this Authorization Rule have Send permissions to the ServiceBus Namespace? 
  - `manage` - (Optional) - Defaults to `false`. Does this Authorization Rule have Manage permissions to the ServiceBus Namespace?

  Example Inputs:
  ```hcl
  authorization_rules = {
    testRule = {
      send   = true
      listen = true
      manage = true
    }
  }
  ```
  DESCRIPTION
}

variable "infrastructure_encryption_enabled" {
  type        = bool
  default     = true
  nullable    = false
  description = "Defaults to true. Used to specify whether enable Infrastructure Encryption (Double Encryption). Changing this forces a new resource to be created. Requires customer_managed_key."
}

variable "customer_managed_key" {
  type = object({
    key_name              = string
    key_vault_resource_id = string

    key_version = optional(string, null)

    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
  default     = null
  description = <<DESCRIPTION
  Defaults to `null`. Ignored for Basic and Standard. Defines a customer managed key to use for encryption.

  - `key_name`               - (Required) - The key name for the customer managed key in the key vault.
  - `key_vault_resource_id`  - (Required) - The full Azure Resource ID of the key_vault where the customer managed key will be referenced from.
  - `key_version`            - (Optional) - Defaults to `null`. The version of the key to use if it is null it will use the latest version of the key. It will also auto rotate when the key in the key vault is rotated.

  - `user_assigned_identity` - (Required) - The user assigned identity to use when access the key vault
    - `resource_id`          - (Required) - The full Azure Resource ID of the user assigned identity.

  > Note: Remember to assign permission to the managed identity to access the key vault key. The Key vault used must have enabled soft delete and purge protection. The minimun required permissions is "Key Vault Crypto Service Encryption User"
  > Note: If you require to control "infrastructure encryption" use the parameter `infrastructure_encryption_enabled` in the module configuration.

  Example Inputs:
  ```hcl
  customer_managed_key = {
    key_name               = "sample-customer-key"
    key_version            = 03c89971825b4a0d84905c3597512260
    key_vault_resource_id  = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.KeyVault/vaults/{keyVaultName}"
    
    user_assigned_identity {
      resource_id = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{managedIdentityName}"
    }
  }
  ```
  DESCRIPTION

  validation {
    condition     = var.customer_managed_key == null || can(regex("^/subscriptions/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/resourceGroups/.+/providers/Microsoft.ManagedIdentity/userAssignedIdentities/.+$", var.customer_managed_key.user_assigned_identity.resource_id))
    error_message = "Managed identity resource IDs must be in the format /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{managedIdentityName}"
  }

  validation {
    condition     = var.customer_managed_key == null || can(regex("^/subscriptions/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/resourceGroups/.+/providers/Microsoft.KeyVault/vaults/.+$", var.customer_managed_key.key_vault_resource_id))
    error_message = "Key vault resource IDs must be in the format /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.KeyVault/vaults/{keyVaultName}"
  }

  validation {
    condition     = var.customer_managed_key == null ? true : var.customer_managed_key.key_name != null
    error_message = "key_name must have a value"
  }
}

variable "network_rule_config" {
  type = object({
    trusted_services_allowed = optional(bool, false)
    cidr_or_ip_rules         = optional(set(string), [])
    default_action           = optional(string, "Allow")

    network_rules = optional(set(object({
      subnet_id = string
    })), [])
  })
  nullable    = false
  default     = {}
  description = <<DESCRIPTION
  Defaults to `{}`. Ignored for Basic and Standard. Defines the network rules configuration for the resource.

  - `trusted_services_allowed` - (Optional) - Are Azure Services that are known and trusted for this resource type are allowed to bypass firewall configuration? 
  - `cidr_or_ip_rules`         - (Optional) - Defaults to `[]`. One or more IP Addresses, or CIDR Blocks which should be able to access the ServiceBus Namespace.
  - `default_action`           - (Optional) - Defaults to `Allow`. Specifies the default action for the Network Rule Set when a rule (IP, CIDR or subnet) doesn't match. Possible values are `Allow` and `Deny`.

  - `network_rules` - (Optional) - Defaults to `[]`.
    - `subnet_id`                            - (Required) - The Subnet ID which should be able to access this ServiceBus Namespace.

  > Note: Remember to enable Microsoft.KeyVault service endpoint on the subnet.

  Example Inputs:
  ```hcl
  network_rule_config = {
    trusted_services_allowed = true
    default_action           = "Allow"
    cidr_or_ip_rules         = ["79.0.0.0", "80.0.0.0/24"]

    network_rules = [
      {
        subnet_id                            = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}"
      }
    ]
  }
  ```
  DESCRIPTION

  validation {
    condition     = contains(["Allow", "Deny"], var.network_rule_config.default_action)
    error_message = "Default action can only be Allow or Deny"
  }

  validation {
    condition = alltrue([
      for value in var.network_rule_config.network_rules :
      can(regex("^/subscriptions/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/resourceGroups/.+/providers/Microsoft.Network/virtualNetworks/.+/subnets/.+$", value.subnet_id))
    ])
    error_message = "Subnet IDs must be in the format /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}"
  }

  validation {
    condition = alltrue([
      for value in var.network_rule_config.cidr_or_ip_rules :
      value == null ? false : strcontains(value, "/") == false || can(cidrhost(value, 0))
    ])
    error_message = "Allowed Ips must be valid IPv4 CIDR."
  }

  validation {
    condition = alltrue([
      for value in var.network_rule_config.cidr_or_ip_rules :
      value == null ? false : strcontains(value, "/") || can(regex("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", value))
    ])
    error_message = "Allowed IPs must be valid IPv4."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = <<DESCRIPTION
  Defaults to `{}`. A mapping of tags to assign to the resource. These tags will propagate to any child resource unless overriden when creating the child resource

  Example Inputs:
  ```hcl
  tags = {
    environment = "testing"
  }
  ```
  DESCRIPTION
}
