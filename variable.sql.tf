variable "sql_databases" {
  type = map(object({
    name       = optional(string, null)
    throughput = optional(number, null)

    autoscale_settings = optional(object({
      max_throughput = number
    }), null)

    containers = optional(map(object({
      partition_key_path = string

      name                   = optional(string, null)
      throughput             = optional(number, null)
      default_ttl            = optional(number, null)
      analytical_storage_ttl = optional(number, null)

      unique_keys = optional(list(object({
        paths = set(string)
      })), [])

      autoscale_settings = optional(object({
        max_throughput = optional(number, null)
      }), null)

      functions = optional(map(object({
        body = string
        name = optional(string)
      })), {})

      stored_procedures = optional(map(object({
        body = string
        name = optional(string)
      })), {})

      triggers = optional(map(object({
        body      = string
        type      = string
        operation = string
        name      = optional(string)
      })), {})

      conflict_resolution_policy = optional(object({
        mode                          = string
        conflict_resolution_path      = optional(string, null)
        conflict_resolution_procedure = optional(string, null)
      }), null)

      indexing_policy = optional(object({
        indexing_mode = optional(string, "consistent")

        included_paths = optional(set(object({
          path = string
        })), [])

        excluded_paths = optional(set(object({
          path = string
        })), [])

        composite_indexes = optional(set(object({
          indexes = set(object({
            path  = string
            order = string
          }))
        })), [])

        spatial_indexes = optional(set(object({
          path = string
        })), [])
      }), null)

    })), {})
  }))
  nullable    = false
  default     = {}
  description = <<DESCRIPTION
  
  DESCRIPTION

  validation {
    condition = alltrue(
      [
        for key, value in var.sql_databases : 
        try(value.default_ttl, null) != null ? value.default_ttl >= -1 && value.default_ttl <= 2147483647 : true
      ]
    )
    error_message = "The 'default_ttl' in the database value must be between -1 and 2147483647 if specified."
  }

  validation {
    condition = alltrue(
      [
        for key, value in var.sql_databases : 
        try(value.analytical_storage_ttl, null) != null ? value.analytical_storage_ttl >= -1 && value.analytical_storage_ttl <= 2147483647 : true
      ]
    )
    error_message = "The 'analytical_storage_ttl' in the database value must be between -1 and 2147483647 if specified."
  }

  validation {
    condition = alltrue(
      [for key, value in var.sql_databases : value.throughput != null ? value.throughput >= 1 : true]
    )
    error_message = "The 'throughput' in the database value must be greater than or equal to 1 if specified."
  }

  validation {
    condition = alltrue(
      [
        for key, value in var.sql_databases : 
        try(value.autoscale_settings.max_throughput, null) != null ? value.autoscale_settings.max_throughput >= 1000 && value.autoscale_settings.max_throughput <= 1000000 : true
      ]
    )
    error_message = "The 'max_throughput' in the autoscale_settings value must be between 1000 and 1000000 if specified."
  }

  validation {
    condition = alltrue(
      [
        for key, value in var.sql_databases : 
        try(value.autoscale_settings.max_throughput, null) != null ? value.autoscale_settings.max_throughput % 1000 == 0 : true
      ]
    )
    error_message = "The 'max_throughput' in the autoscale_settings value must be a multiple of 1000 if specified."
  }

  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.sql_databases : 
          [
            for container_key, container_params in db_params.containers :
            try(container_params.conflict_resolution_policy.mode, null) != null ? contains(["Custom", "LastWriterWins"], container_params.conflict_resolution_policy.mode) : true
          ]
      ])
    )
    error_message = "The 'conflict_resolution_policy.mode' must be either 'Custom' or 'LastWriterWins' if specified."
  }

  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.sql_databases : 
          [
            for container_key, container_params in db_params.containers :
            try(container_params.conflict_resolution_policy.mode, "") == "LastWriterWins" ? try(container_params.conflict_resolution_policy.conflict_resolution_path, null) != null : true
          ]
      ])
    )
    error_message = "The 'conflict_resolution_path' must be specified when the conflict resolution mode is 'LastWriterWins'."
  }

  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.sql_databases : 
          [
            for container_key, container_params in db_params.containers :
            try(container_params.conflict_resolution_policy.mode, "") == "Custom" ? try(container_params.conflict_resolution_policy.conflict_resolution_procedure, null) != null : true
          ]
      ])
    )
    error_message = "The 'conflict_resolution_procedure' must be specified when the conflict resolution mode is 'Custom'."
  }

  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.sql_databases : 
          [
            for container_key, container_params in db_params.containers :
            [
              for trigger_key, trigger_params in container_params.triggers :
              contains(["Pre", "Post"], trigger_params.type)
            ]
          ]
      ])
    )
    error_message = "The 'type' in the trigger value must be either 'Pre' or 'Post'."
  }

  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.sql_databases : 
          [
            for container_key, container_params in db_params.containers :
            [
              for trigger_key, trigger_params in container_params.triggers :
              contains(["All", "Create", "Delete", "Replace", "Update"], trigger_params.operation)
            ]
          ]
      ])
    )
    error_message = "The 'operation' in the trigger value must be either 'All', 'Create', 'Delete', 'Replace', or 'Update'."
  }

  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.sql_databases : 
          [
            for container_key, container_params in db_params.containers :
            [
              for trigger_key, trigger_params in container_params.triggers :
              trimspace(coalesce(trigger_params.body, "")) != ""
            ]
          ]
      ])
    )
    error_message = "The 'body' in the trigger value must not be empty."
  }

  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.sql_databases : 
          [
            for container_key, container_params in db_params.containers :
            [
              for function_key, function_params in container_params.functions :
              trimspace(coalesce(function_params.body, "")) != ""
            ]
          ]
      ])
    )
    error_message = "The 'body' in the function value must not be empty."
  }

  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.sql_databases : 
          [
            for container_key, container_params in db_params.containers :
            [
              for stored_key, stored_params in container_params.stored_procedures :
              trimspace(coalesce(stored_params.body, "")) != ""
            ]
          ]
      ])
    )
    error_message = "The 'body' in the stored procedures value must not be empty."
  }
}
