variable "cassandra_keyspaces" {
  type = map(object({
    name = string

    throughput = optional(number)
    autoscale_settings = optional(object({
      max_throughput = number
    }))

    tables = optional(map(object({
      name                   = string
      default_ttl            = optional(number)
      analytical_storage_ttl = optional(number)
      throughput             = optional(number)
      autoscale_settings = optional(object({
        max_throughput = number
      }))
      schema = object({
        columns = list(object({
          name = string
          type = string
        }))
        partition_keys = list(object({
          name = string
        }))
        cluster_keys = optional(list(object({
          name     = string
          order_by = string
        })), [])
      })
    })), {})
  }))
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
A map of Cassandra keyspaces to create in the Cosmos DB account. The map keys identify keyspaces in the output. Cassandra resources require the account's `EnableCassandra` capability and cannot be combined with SQL, MongoDB, or Gremlin database inputs.

- `name` - The Cassandra keyspace name.
- `throughput` - Optional provisioned request units per second. Conflicts with `autoscale_settings`.
- `autoscale_settings.max_throughput` - Optional autoscale maximum throughput. Conflicts with `throughput`.
- `tables` - A map of Cassandra tables in the keyspace, keyed by the table identifiers used in the output.
- `tables.name` - The Cassandra table name.
- `tables.default_ttl` - Optional default time to live, in seconds.
- `tables.analytical_storage_ttl` - Optional analytical storage time to live, in seconds.
- `tables.throughput` - Optional provisioned request units per second. Conflicts with `tables.autoscale_settings`.
- `tables.autoscale_settings.max_throughput` - Optional autoscale maximum throughput. Conflicts with `tables.throughput`.
- `tables.schema.columns` - Cassandra column definitions; each column has a `name` and Cassandra `type`.
- `tables.schema.partition_keys` - Cassandra partition key column names. At least one partition key is required.
- `tables.schema.cluster_keys` - Optional clustering key definitions; each has a `name` and `order_by` (`Asc` or `Desc`).

Provisioned throughput must be at least 400 RU/s. Autoscale maximum throughput must be between 1,000 and 1,000,000 RU/s in increments of 1,000.
DESCRIPTION

  validation {
    condition = alltrue([
      for keyspace in values(var.cassandra_keyspaces) :
      !(keyspace.throughput != null && keyspace.autoscale_settings != null)
    ])
    error_message = "A Cassandra keyspace cannot set both throughput and autoscale_settings."
  }

  validation {
    condition = alltrue([
      for keyspace in values(var.cassandra_keyspaces) :
      keyspace.throughput == null || keyspace.throughput >= 400
    ])
    error_message = "Cassandra keyspace throughput must be at least 400 RU/s."
  }

  validation {
    condition = alltrue([
      for keyspace in values(var.cassandra_keyspaces) :
      keyspace.autoscale_settings == null || (
        keyspace.autoscale_settings.max_throughput >= 1000 &&
        keyspace.autoscale_settings.max_throughput <= 1000000 &&
        keyspace.autoscale_settings.max_throughput % 1000 == 0
      )
    ])
    error_message = "Cassandra keyspace autoscale max_throughput must be between 1,000 and 1,000,000 RU/s in increments of 1,000."
  }

  validation {
    condition = alltrue(flatten([
      for keyspace in values(var.cassandra_keyspaces) : [
        for table in values(keyspace.tables) :
        !(table.throughput != null && table.autoscale_settings != null)
      ]
    ]))
    error_message = "A Cassandra table cannot set both throughput and autoscale_settings."
  }

  validation {
    condition = alltrue(flatten([
      for keyspace in values(var.cassandra_keyspaces) : [
        for table in values(keyspace.tables) :
        table.throughput == null || table.throughput >= 400
      ]
    ]))
    error_message = "Cassandra table throughput must be at least 400 RU/s."
  }

  validation {
    condition = alltrue(flatten([
      for keyspace in values(var.cassandra_keyspaces) : [
        for table in values(keyspace.tables) :
        table.autoscale_settings == null || (
          table.autoscale_settings.max_throughput >= 1000 &&
          table.autoscale_settings.max_throughput <= 1000000 &&
          table.autoscale_settings.max_throughput % 1000 == 0
        )
      ]
    ]))
    error_message = "Cassandra table autoscale max_throughput must be between 1,000 and 1,000,000 RU/s in increments of 1,000."
  }

  validation {
    condition = alltrue(flatten([
      for keyspace in values(var.cassandra_keyspaces) : [
        for table in values(keyspace.tables) :
        length(table.schema.partition_keys) > 0 &&
        alltrue([for cluster_key in table.schema.cluster_keys : contains(["Asc", "Desc"], cluster_key.order_by)])
      ]
    ]))
    error_message = "Each Cassandra table schema must include at least one partition key, and clustering key order_by values must be Asc or Desc."
  }
}

variable "ignore_body_changes" {
  type = object({
    documentdb_database_accounts_cassandra_keyspaces        = optional(list(string), [])
    documentdb_database_accounts_cassandra_keyspaces_tables = optional(list(string), [])
  })
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
Body-relative dot-notation paths ignored on each Cassandra resource. Ignored configuration is not sent to Azure, and changes take effect only after apply.

- `documentdb_database_accounts_cassandra_keyspaces` - Paths ignored on Cassandra keyspace resources.
- `documentdb_database_accounts_cassandra_keyspaces_tables` - Paths ignored on Cassandra table resources.
DESCRIPTION
}

variable "resource_types" {
  type = object({
    documentdb_database_accounts_cassandra_keyspaces        = optional(string, "Microsoft.DocumentDB/databaseAccounts/cassandraKeyspaces@2026-03-15")
    documentdb_database_accounts_cassandra_keyspaces_tables = optional(string, "Microsoft.DocumentDB/databaseAccounts/cassandraKeyspaces/tables@2026-03-15")
  })
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the Cassandra resources.

- `documentdb_database_accounts_cassandra_keyspaces` - Resource type and API-version override for Cassandra keyspaces.
- `documentdb_database_accounts_cassandra_keyspaces_tables` - Resource type and API-version override for Cassandra tables.
DESCRIPTION
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to the Cassandra keyspace and table resources. Defaults to `null` (provider defaults).

- `error_message_regex` - Optional list of error-message patterns that trigger retries.
- `interval_seconds` - Optional initial retry interval, in seconds.
- `max_interval_seconds` - Optional maximum retry interval, in seconds.
DESCRIPTION
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Default operation timeouts applied to the Cassandra keyspace and table resources. Values are Go duration strings; `null` uses provider defaults.

- `create` - Optional create timeout.
- `read` - Optional read timeout.
- `update` - Optional update timeout.
- `delete` - Optional delete timeout.
DESCRIPTION
}
