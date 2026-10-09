variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  Defaults to `{}`. A map of role assignments to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `role_definition_id_or_name`             - (Required) - The ID or name of the role definition to assign to the principal.
  - `principal_id`                           - (Required) - The ID of the principal to assign the role to.
  - `description`                            - (Optional) - The description of the role assignment. Changing this forces a new resource to be created.
  - `skip_service_principal_aad_check`       - (Optional) - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `delegated_managed_identity_resource_id` - (Optional) - The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type`                         - (Optional) - The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute. Changing this forces a new resource to be created.
  - `condition`                              - (Optional) - The condition which will be used to scope the role assignment. Changing this forces a new resource to be created.
  - `condition_version`                      - (Optional) - The version of the condition syntax. Leave as `null` if you are not using a condition. If you are, the valid value is `2.0`. When `condition` is set and this is left as `null`, `2.0` is used. Can only be set together with `condition`. Changing this forces a new resource to be created.

  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

  Example Inputs:
  ```hcl
  role_assignments = {
    "key" = {
      skip_service_principal_aad_check = false
      role_definition_id_or_name       = "Contributor"
      description                      = "This is a test role assignment"
      principal_id                     = "eb5260bd-41f3-4019-9e03-606a617aec13"
      principal_type                   = "User"
    }
  }
  ```
  DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue([
      for k, v in var.role_assignments :
      trimspace(v.role_definition_id_or_name) != null
    ])
    error_message = "'role_definition_id_or_name' must be set and not empty value"
  }
  validation {
    condition = alltrue([
      for k, v in var.role_assignments :
      can(regex("^([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})$", v.principal_id))
    ])
    error_message = "'principal_id' must be a valid GUID"
  }
  validation {
    condition = alltrue([
      for k, v in var.role_assignments :
      v.principal_type == null ? true : contains(["User", "Group", "ServicePrincipal"], v.principal_type)
    ])
    error_message = "'principal_type' must be one of 'User', 'Group' or 'ServicePrincipal', or null"
  }
  validation {
    condition = alltrue([
      for k, v in var.role_assignments :
      v.condition_version == null || v.condition != null
    ])
    error_message = "'condition_version' can only be set when 'condition' is also set"
  }
}
