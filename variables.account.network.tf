variable "minimal_tls_version" {
  type        = string
  nullable    = false
  default     = "Tls12"
  description = "Defaults to `Tls12`. Specifies the minimal TLS version for the CosmosDB account. Possible values are: `Tls`, `Tls11`, and `Tls12`"

  validation {
    condition     = var.minimal_tls_version == null || can(index(["Tls", "Tls11", "Tls12"], var.minimal_tls_version))
    error_message = "The minimal_tls_version variable must be 'Tls', 'Tls1' or 'Tls12'."
  }
}

variable "public_network_access_enabled" {
  type        = bool
  nullable    = false
  default     = true
  description = "Defaults to `true`. Whether or not public network access is allowed for this CosmosDB account."
}

variable "network_acl_bypass_for_azure_services" {
  type        = bool
  nullable    = false
  default     = false
  description = "Defaults to `false`. If Azure services can bypass ACLs."
}

variable "network_acl_bypass_ids" {
  type        = set(string)
  nullable    = false
  default     = []
  description = "Defaults to `[]`. The list of resource Ids for Network Acl Bypass for this Cosmos DB account."
}

variable "ip_range_filter" {
  type        = set(string)
  nullable    = false
  default     = []
  description = <<DESCRIPTION
  Defaults to `[]`. CosmosDB Firewall Support: This value specifies the set of IP addresses or IP address ranges in CIDR form to be included as the allowed list of client IPs for a given database account.

  > Note: To enable the "Allow access from the Azure portal" behavior, you should add the IP addresses provided by the documentation to this list. https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-configure-firewall#allow-requests-from-the-azure-portal
  > Note: To enable the "Accept connections from within public Azure datacenters" behavior, you should add 0.0.0.0 to the list, see the documentation for more details. https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-configure-firewall#allow-requests-from-global-azure-datacenters-or-other-sources-within-azure

  DESCRIPTION

  validation {
    condition = alltrue([
      for value in var.ip_range_filter :
      value == null ? false : strcontains(value, "/") == false || can(cidrhost(value, 0))
    ])
    error_message = "Allowed Ips must be valid IPv4 CIDR."
  }

  validation {
    condition = alltrue([
      for value in var.ip_range_filter :
      value == null ? false : strcontains(value, "/") || can(regex("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", value))
    ])
    error_message = "Allowed IPs must be valid IPv4."
  }
}

variable "virtual_network_rules" {
  type = set(object({
    subnet_id = string
  }))
  nullable    = false
  default     = []
  description = <<DESCRIPTION
  Defaults to `[]`. Used to define which subnets are allowed to access this CosmosDB account.

  - `subnet_id` - (Required) - The ID of the virtual network subnet.

  > Note: Remember to enable Microsoft.AzureCosmosDB service endpoint on the subnet.

  Example inputs:
  ```hcl
  virtual_network_rule = [
    {
      subnet_id = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}"
    }
  ]
  ```
  DESCRIPTION

  validation {
    condition = alltrue([
      for value in var.virtual_network_rules :
      can(regex("^/subscriptions/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/resourceGroups/.+/providers/Microsoft.Network/virtualNetworks/.+/subnets/.+$", value.subnet_id))
    ])
    error_message = "'subnet_id' must be in the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}'"
  }
}