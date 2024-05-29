variable "sql_dedicated_gateway" {
  type = object({
    instance_size  = string
    instance_count = optional(number, 1)
  })
  default     = null
  description = <<DESCRIPTION
  Defaults to `null`. Manages a SQL Dedicated Gateway within a Cosmos DB Account.

  - `instance_size`  - (Optional) - The instance size for the CosmosDB SQL Dedicated Gateway. Changing this forces a new resource to be created. Possible values are `Cosmos.D4s`, `Cosmos.D8s` and `Cosmos.D16s`
  - `instance_count` - (Optional) - The instance count for the CosmosDB SQL Dedicated Gateway. Possible value is between `1` and `5`.

  > Note: To create a dedicated gateway in a zone redundant region you must request Azure to enable it into your account. See more in: https://learn.microsoft.com/en-us/azure/cosmos-db/dedicated-gateway#provisioning-the-dedicated-gateway

  Example inputs: 
  ```hcl
  sql_dedicated_gateway = {
    instance_count = 1
    instance_size  = "Cosmos.D4s"
  }
  ```
  DESCRIPTION

  validation {
    condition     = try(var.sql_dedicated_gateway.instance_count, null) != null ? var.sql_dedicated_gateway.instance_count >= 1 && var.sql_dedicated_gateway.instance_count <= 5 : true
    error_message = "The 'instance_count' in the sql_dedicated_gateway value must be between 1 and 5 if specified."
  }

  validation {
    condition     = try(var.sql_dedicated_gateway.instance_size, null) != null ? can(index(["Cosmos.D4s", "Cosmos.D8s", "Cosmos.D16s"], var.sql_dedicated_gateway.instance_size)) : true
    error_message = "The 'instance_size' in the sql_dedicated_gateway value must be 'Cosmos.D4s', 'Cosmos.D8s' or 'Cosmos.D16s' if specified."
  }
}

variable "sql_databases" {
  type = map(object({
    name = string

    throughput = optional(number, null)

    autoscale_settings = optional(object({
      max_throughput = number
    }), null)

    containers = optional(map(object({
      partition_key_path = string
      name               = string

      throughput             = optional(number, null)
      default_ttl            = optional(number, null)
      analytical_storage_ttl = optional(number, null)

      unique_keys = optional(list(object({
        paths = set(string)
      })), [])

      autoscale_settings = optional(object({
        max_throughput = number
      }), null)

      functions = optional(map(object({
        body = string
        name = string
      })), {})

      stored_procedures = optional(map(object({
        body = string
        name = string
      })), {})

      triggers = optional(map(object({
        body      = string
        type      = string
        operation = string
        name      = string
      })), {})

      conflict_resolution_policy = optional(object({
        mode                          = string
        conflict_resolution_path      = optional(string, null)
        conflict_resolution_procedure = optional(string, null)
      }), null)

      indexing_policy = optional(object({
        indexing_mode = string

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
  Defaults to `{}`. Manages SQL Databases within a Cosmos DB Account.

  - `name`       - (Required) - Specifies the name of the Cosmos DB SQL Container. Changing this forces a new resource to be created.
  - `throughput` - (Optional) - Defaults to `null`. The throughput of SQL database (RU/s). Must be set in increments of `100`. The minimum value is `400`. This must be set upon database creation otherwise it cannot be updated without a manual terraform destroy-apply.

  - `autoscale_settings` - (Optional) - Defaults to `null`. This must be set upon database creation otherwise it cannot be updated without a manual terraform destroy-apply.
    - `max_throughput` - (Required) - The maximum throughput of the SQL database (RU/s). Must be between `1,000` and `1,000,000`. Must be set in increments of `1,000`. Conflicts with `throughput`.

  - `containers` - (Optional) - Defaults to `{}`. Manages SQL Containers within a Cosmos DB Account.
    - `partition_key_path`     - (Required) - Define a partition key. Changing this forces a new resource to be created.
    - `name`                   - (Required) - Specifies the name of the Cosmos DB SQL Container. Changing this forces a new resource to be created.
    - `throughput`             - (Optional) - Defaults to `null`. The throughput of SQL container (RU/s). Must be set in increments of `100`. The minimum value is `400`. This must be set upon container creation otherwise it cannot be updated without a manual terraform destroy-apply.
    - `default_ttl`            - (Optional) - Defaults to `null`. The default time to live of SQL container. If missing, items are not expired automatically. If present and the value is set to `-1`, it is equal to infinity, and items don't expire by default. If present and the value is set to some number n - items will expire n seconds after their last modified time.
    - `analytical_storage_ttl` - (Optional) - Defaults to `null`. The default time to live of Analytical Storage for this SQL container. If present and the value is set to `-1`, it is equal to infinity, and items don't expire by default. If present and the value is set to some number n - items will expire n seconds after their last modified time.

    - `unique_keys` - (Optional) - Defaults to `[]`. The unique keys of the container.
      - `paths` - (Required) - A list of paths to use for this unique key. Changing this forces a new resource to be created.

    - `autoscale_settings` - (Optional) - Defaults to `null`. This must be set upon database creation otherwise it cannot be updated without a manual terraform destroy-apply.
      - `max_throughput` - (Required) - The maximum throughput of the SQL container (RU/s). Must be between `1,000` and `1,000,000`. Must be set in increments of `1,000`. Conflicts with `throughput`.
    
    - `functions` - (Optional) - Defaults to `{}`. Manages SQL User Defined Functions.
      - `body` - (Required) - Body of the User Defined Function.
      - `name` - (Required) - The name which should be used for this SQL User Defined Function. Changing this forces a new SQL User Defined Function to be created.

    - `stored_procedures` - (Optional) - Defaults to `{}`. Manages SQL Stored Procedures within a Cosmos DB Account SQL Database.
      - `body` - (Required) - The body of the stored procedure.
      - `name` - (Required) - Specifies the name of the Cosmos DB SQL Stored Procedure. Changing this forces a new resource to be created.

    - `triggers` - (Optional) -  Defaults to `{}`. Manages SQL Triggers.
      - `body`      - (Required) - Body of the Trigger.
      - `type`      - (Required) - Type of the Trigger. Possible values are `Pre` and `Post`.
      - `operation` - (Required) - The operation the trigger is associated with. Possible values are `All`, `Create`, `Update`, `Delete` and `Replace`.
      - `name`      - (Required) - The name which should be used for this SQL Trigger. Changing this forces a new SQL Trigger to be created.

    - `conflict_resolution_policy` - (Optional) - Defaults to `null`. The conflict resolution policy of the container. Changing this forces a new resource to be created.
      - `mode`                          - (Required) - Indicates the conflict resolution mode. Possible values include: `LastWriterWins` and `Custom`.
      - `conflict_resolution_path`      - Required if `LastWriterWins` is set as `mode` - The conflict resolution path.
      - `conflict_resolution_procedure` - Required if `Custom` is set as `mode` - The procedure to resolve conflicts .

    - `indexing_policy` - (Optional) - Defaults to `{}`. The indexing policy of the container.
      - `indexing_mode` - (Required) - Indicates the indexing mode. Possible values include: `consistent` and `none`

      - `included_paths` - (Optional) - Defaults to `[]`. Either included_path or excluded_path must contain the path `/*`
        - `path` - (Required) - Path for which the indexing behaviour applies to.

      - `excluded_paths` - (Optional) - Defaults to `[]`. Either included_path or excluded_path must contain the path `/*`
        - `path` - (Required) - Path that is excluded from indexing.

      - `composite_indexes` - (Optional) - Defaults to `[]`. The composite indexes of the indexing policy.
        - `indexes` - (Required) - The indexes of the composite indexes.
          - `path`  - (Required) - Path for which the indexing behaviour applies to.
          - `order` - (Required) - Order of the index. Possible values are `Ascending` or `Descending`.

      - `spatial_indexes` - (Optional) - Defaults to `[]`. The spatial indexes of the indexing policy.
        - `path` - (Required) -  Path for which the indexing behaviour applies to. According to the service design, all spatial types including LineString, MultiPolygon, Point, and Polygon will be applied to the path.

  > Note: Switching between autoscale and manual throughput is not supported via Terraform and must be completed via the Azure Portal and refreshed.
  > Note: For indexing policy See more in: https://learn.microsoft.com/en-us/azure/cosmos-db/nosql/how-to-manage-indexing-policy?tabs=dotnetv3%2Cpythonv3
  
  Example inputs:
  ```hcl
  sql_databases = {
    database1 = {
      name       = "database1"
      throughput = 400

      # autoscale_settings = {
      #   max_throughput = 4000
      # }

      containers = {
        container1 = {
          partition_key_path = "/id"
          name               = "container1"
          throughput         = 400
          default_ttl        = 1000
          analytical_storage_ttl = 1000

          unique_keys = [
            {
              paths = ["/field1", "/field2"]
            }
          ]

          # autoscale_settings = {
          #   max_throughput = 4000
          # }

          functions = {
            function1 = {
              name = "functionName"
              body = "function function1() { }"
            }
          }

          stored_procedures = {
            stored1 = {
              name = "storedName"
              body = "function stored1() { }"
            }
          }

          triggers = {
            trigger1 = {
              name      = "triggerName"
              body      = "function trigger1() { }"
              type      = "Pre"
              operation = "All"
            }
          }

          conflict_resolution_policy = {
            mode                     = "LastWriterWins"
            conflict_resolution_path = "/customProperty"
          }

          indexing_policy = {
            indexing_mode = "consistent"

            included_paths = [
              {
                path = "/*"
              }
            ]

            excluded_paths = [
              {
                path = "/excluded/*"
              }
            ]

            composite_indexes = [
              {
                indexes = [
                  {
                    path  = "/field1"
                    order = "ascending"
                  }
                ]
              }
            ]

            spatial_indexes = [
              {
                path = "/location/*"
              }
            ]
          }
        }
      }
    }
  }
  ```
  DESCRIPTION

  validation {
    condition = length(
      [
        for db_key, db_params in var.sql_databases : db_params.name
        ]) == length(distinct(
        [
          for db_key, db_params in var.sql_databases : db_params.name
      ])
    )
    error_message = "The 'name' in the sql database value must be unique."
  }

  validation {
    condition = alltrue(
      [
        for db_key, db_params in var.sql_databases :
        length(
          [
            for container_key, container_params in db_params.containers : container_params.name
          ]
          ) == length(distinct(
            [
              for container_key, container_params in db_params.containers : container_params.name
            ]
        ))
    ])
    error_message = "The 'name' in the sql container value must be unique withing a sql database."
  }

  validation {
    condition = alltrue(flatten(
      [
        for db_key, db_params in var.sql_databases :
        [
          for container_key, container_params in db_params.containers :
          length(
            [
              for function_key, function_params in container_params.functions : function_params.name
            ]
            ) == length(distinct(
              [
                for function_key, function_params in container_params.functions : function_params.name
              ]
          ))
        ]
    ]))
    error_message = "The 'name' in the sql function value must be unique within a container."
  }

  validation {
    condition = alltrue(flatten(
      [
        for db_key, db_params in var.sql_databases :
        [
          for container_key, container_params in db_params.containers :
          length(
            [
              for trigger_key, trigger_params in container_params.triggers : trigger_params.name
            ]
            ) == length(distinct(
              [
                for trigger_key, trigger_params in container_params.triggers : trigger_params.name
              ]
          ))
        ]
    ]))
    error_message = "The 'name' in the sql triggers value must be unique within a container."
  }

  validation {
    condition = alltrue(flatten(
      [
        for db_key, db_params in var.sql_databases :
        [
          for container_key, container_params in db_params.containers :
          length(
            [
              for stored_key, stored_params in container_params.stored_procedures : stored_params.name
            ]
            ) == length(distinct(
              [
                for stored_key, stored_params in container_params.stored_procedures : stored_params.name
              ]
          ))
        ]
    ]))
    error_message = "The 'name' in the sql stored procedure value must be unique within a container."
  }

  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.sql_databases :
        [
          for container_key, container_params in db_params.containers :
          trimspace(coalesce(container_params.partition_key_path, " ")) != ""
        ]
      ])
    )
    error_message = "The 'partition_key_path' in the containers value must not be empty."
  }

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
      [for key, value in var.sql_databases : value.throughput != null ? value.throughput >= 400 : true]
    )
    error_message = "The 'throughput' in the database value must be greater than or equal to 400 if specified."
  }

  validation {
    condition = alltrue(
      [
        for db_key, db_params in var.sql_databases :
        db_params.throughput != null ? db_params.throughput % 100 == 0 : true
      ]
    )
    error_message = "The 'throughput' value in the 'autoscale_settings' at the database level must be a multiple of 100 if specified."
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
      [
        for key, value in var.sql_databases :
        try(value.autoscale_settings.max_throughput, null) != null && value.throughput != null ? false : true
      ]
    )
    error_message = "The 'throughput' and 'autoscale_settings.max_throughput' cannot be specified at the same time at database level."
  }

  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.sql_databases :
        [
          for container_key, container_params in db_params.containers :
          container_params.throughput != null ? container_params.throughput >= 400 : true
        ]
      ])
    )
    error_message = "The 'throughput' value at the container level must be greater than or equal to 400 if specified."
  }

  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.sql_databases :
        [
          for container_key, container_params in db_params.containers :
          container_params.throughput != null ? container_params.throughput % 100 == 0 : true
        ]
      ])
    )
    error_message = "The 'throughput' value in the 'autoscale_settings' at the container level must be a multiple of 100 if specified."
  }

  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.sql_databases :
        [
          for container_key, container_params in db_params.containers :
          try(container_params.autoscale_settings.max_throughput, null) != null ? container_params.autoscale_settings.max_throughput >= 1000 && container_params.autoscale_settings.max_throughput <= 1000000 : true
        ]
      ])
    )
    error_message = "The 'max_throughput'value in the 'autoscale_settings' at the container level must be between 1000 and 1000000 if specified."
  }

  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.sql_databases :
        [
          for container_key, container_params in db_params.containers :
          try(container_params.autoscale_settings.max_throughput, null) != null ? container_params.autoscale_settings.max_throughput % 1000 == 0 : true
        ]
      ])
    )
    error_message = "The 'max_throughput' value in the 'autoscale_settings' at the container level must be a multiple of 1000 if specified."
  }

  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.sql_databases :
        [
          for container_key, container_params in db_params.containers :
          try(container_params.autoscale_settings.max_throughput, null) != null && container_params.throughput != null ? false : true
        ]
      ])
    )
    error_message = "The 'throughput' and 'autoscale_settings.max_throughput' cannot be specified at the same time at container level."
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
          try(container_params.conflict_resolution_policy.mode, "") == "LastWriterWins" ? trimspace(try(container_params.conflict_resolution_policy.conflict_resolution_path, "")) != "" : true
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
          try(container_params.conflict_resolution_policy.mode, "") == "Custom" ? trimspace(try(container_params.conflict_resolution_policy.conflict_resolution_procedure, "")) != "" : true
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
            trimspace(coalesce(trigger_params.body, " ")) != ""
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
            trimspace(coalesce(function_params.body, " ")) != ""
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
            trimspace(coalesce(stored_params.body, " ")) != ""
          ]
        ]
      ])
    )
    error_message = "The 'body' in the stored procedures value must not be empty."
  }

  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.sql_databases :
        [
          for container_key, container_params in db_params.containers :
          try(container_params.indexing_policy.indexing_mode, null) != null ? contains(["consistent", "none"], container_params.indexing_policy.indexing_mode) : true
        ]
      ])
    )
    error_message = "The 'indexing_mode' in the indexing_policy value must be either 'consistent' or 'none'."
  }

  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.sql_databases :
        [
          for container_key, container_params in db_params.containers :
          [
            for composite_index in try(container_params.indexing_policy.composite_indexes, []) :
            [
              for index in composite_index.indexes :
              contains(["Ascending", "Descending"], index.order)
            ]
          ]
        ]
      ])
    )
    error_message = "The 'order' in the composite index value must be either 'Ascending' or 'Descending'."
  }

  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.sql_databases :
        [
          for container_key, container_params in db_params.containers :
          length(try(container_params.indexing_policy.included_paths, [])) > 0 || length(try(container_params.indexing_policy.excluded_paths, [])) > 0 ? contains(container_params.indexing_policy.included_paths[*].path, "/*") || contains(container_params.indexing_policy.excluded_paths[*].path, "/*") : true
        ]
      ])
    )
    error_message = "Either 'included_paths' or 'excluded_paths' must contain the path '/*' if they are specified"
  }
}
