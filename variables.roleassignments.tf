variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name = string
    principal_id               = string

    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    delegated_managed_identity_resource_id = optional(string, null)

    condition         = optional(string, null) # forced to be here by lint, not supported
    condition_version = optional(string, null) # forced to be here by lint, not supported
  }))
  default  = {}
  nullable = false

  description = <<DESCRIPTION
  Defaults to `{}`. A map of role assignments to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `role_definition_id_or_name`             - (Required) - The ID or name of the role definition to assign to the principal.
  - `principal_id`                           - (Required) - It's a GUID - The ID of the principal to assign the role to. 
  - `description`                            - (Optional) - Defaults to `null`. The description of the role assignment.
  - `delegated_managed_identity_resource_id` - (Optional) - Defaults to `null`. The delegated Azure Resource Id which contains a Managed Identity. This field is only used in cross tenant scenario. Changing this forces a new resource to be created.
  - `skip_service_principal_aad_check`       - (Optional) - Defaults to `false`. If the principal_id is a newly provisioned Service Principal set this value to true to skip the Azure Active Directory check which may fail due to replication lag. This argument is only valid if the principal_id is a Service Principal identity. 
  
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
      v.role_definition_id_or_name != null
    ])
    error_message = "Role definition id or name must be set"
  }

  validation {
    condition = alltrue([
      for k, v in var.role_assignments :
      can(regex("^([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})$", v.principal_id))
    ])
    error_message = "principal_id must be a valid GUID"
  }
}