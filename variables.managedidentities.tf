
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
    error_message = "'user_assigned_resource_ids' must be in the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{managedIdentityName}'"
  }
}