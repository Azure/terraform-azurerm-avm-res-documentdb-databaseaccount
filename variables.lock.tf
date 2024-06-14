variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
  Defaults to `null`. Controls the Resource Lock configuration for this resource. 
  If specified, it will be inherited by child resources unless overriden when creating those child resources. 
  The following properties can be specified:

  - `kind` - (Required) - The type of lock. Possible values are `CanNotDelete` and `ReadOnly`.
  - `name` - (Optional) - The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

  > Note: If you use `ReadOnly` kind lock, you must configure Terraform to use EntraId authentication, as the access of the account keys will be blocked thus terraform won't be to do its job.

  Example Inputs:
  ```hcl
  lock = {
    kind = "CanNotDelete"
    name = "This resource cannot be deleted easily"
  }
  ```
  DESCRIPTION

  validation {
    condition     = var.lock == null ? true : var.lock.kind == null ? false : contains(["CanNotDelete", "ReadOnly"], var.lock.kind)
    error_message = "'kind' must be either 'CanNotDelete' or 'ReadOnly'."
  }
}