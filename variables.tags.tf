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
