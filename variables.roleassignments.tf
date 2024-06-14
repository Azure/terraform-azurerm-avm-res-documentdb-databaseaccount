variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    delegated_managed_identity_resource_id = optional(string, null)

    principal_type    = optional(string, null) # forced to be here by lint, not supported
    condition         = optional(string, null) # forced to be here by lint, not supported
    condition_version = optional(string, null) # forced to be here by lint, not supported
  }))
  default  = {}
  nullable = false

  description = <<DESCRIPTION
  Defaults to `{}`. A map of role assignments to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `role_definition_id_or_name`             - (Required) - The ID or name of the role definition to assign to the principal.
  - `principal_id`                           - (Required) - The ID of the principal to assign the role to.
  - `description`                            - (Optional) - The description of the role assignment.
  - `skip_service_principal_aad_check`       - (Optional) - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `delegated_managed_identity_resource_id` - (Optional) - The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  
  - `principal_type`                         - (Unsupported)
  - `condition`                              - (Unsupported)
  - `condition_version`                      - (Unsupported)

  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

  Example Inputs:
  ```hcl
  role_assignments = {
    "key" = {
      skip_service_principal_aad_check = false
      role_definition_id_or_name       = "Contributor"
      description                      = "This is a test role assignment"
      principal_id                     = "eb5260bd-41f3-4019-9e03-606a617aec13"
    }
  }
  ```
  DESCRIPTION

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
}
