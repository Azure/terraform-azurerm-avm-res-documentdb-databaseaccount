variable "mongo_server_version" {
  type        = string
  description = "The Server Version of a MongoDB account. Defaults to `3.6` Possible values are `4.2`, `4.0`, `3.6`, and `3.2`"
  default     = "3.6"

  validation {
    condition     = can(index(["4.2", "4.0", "3.6", "3.2"], var.mongo_server_version))
    error_message = "The 'mongo_server_version' variable must be '4.2', '4.0', '3.6', or '3.2'."
  }
}

variable "mongo_databases" {
  type = map(object({
    name = string

    throughput = optional(number, null)

    autoscale_settings = optional(object({
      max_throughput = number
    }), null)

    collections = optional(map(object({
      name = string

      default_ttl_seconds = optional(string, null)
      shard_key           = optional(string, null)
      throughput          = optional(number, null)

      autoscale_settings = optional(object({
        max_throughput = number
      }), null)

      index = optional(object({
        keys   = list(string)
        unique = optional(bool, false)
      }), null)

    })), {})
  }))
  nullable    = false
  default     = {}
  description = <<DESCRIPTION
  Defaults to `{}`. Manages SQL Databases within a Cosmos DB Account.

  - `name`       - (Required) - Specifies the name of the Cosmos DB Mongo Database. Changing this forces a new resource to be created.
  - `throughput` - (Optional) - Defaults to `null`. The throughput of the MongoDB database (RU/s). Must be set in increments of `100`. The minimum value is `400`. This must be set upon database creation otherwise it cannot be updated without a manual terraform destroy-apply.

  - `autoscale_settings` - (Optional) - Defaults to `null`. This must be set upon database creation otherwise it cannot be updated without a manual terraform destroy-apply.
    - `max_throughput` - (Required) - The maximum throughput of the SQL database (RU/s). Must be between `1,000` and `1,000,000`. Must be set in increments of `1,000`. Conflicts with `throughput`.

  - `collections` - (Optional) - Defaults to `{}`. Manages a Mongo Collection within a Cosmos DB Account.
    - `name`      - (Required) Specifies the name of the Cosmos DB Mongo Collection. Changing this forces a new resource to be created.

    - `throughput`             - (Optional) - Defaults to `null`. The throughput of the MongoDB collection (RU/s). Must be set in increments of 100. The minimum value is 400. This must be set upon database creation otherwise it cannot be updated without a manual terraform destroy-apply.
    - `default_ttl_seconds`    - (Optional) - Defaults to `null`. The default Time To Live in seconds. If the value is -1, items are not automatically expired.
    - `shard_key             ` - (Optional) - Defaults to `null`. The name of the key to partition on for sharding. There must not be any other unique index keys. Changing this forces a new resource to be created.

    - `autoscale_settings` - (Optional) - Defaults to `null`. This must be set upon database creation otherwise it cannot be updated without a manual terraform destroy-apply.
      - `max_throughput`   - (Required) - The maximum throughput of the MongoDB collection (RU/s). Must be between 1,000 and 1,000,000. Must be set in increments of 1,000. Conflicts with throughput.

    - `Index` - (Optional) - Defaults to `null`. Improve the efficiency of MongoDB database operations.
      - `keys`    - (Required) Specifies the list of user settable keys for each Cosmos DB Mongo Collection.
      - `unique`  - (Optional) Defaults to `false`. Is the index unique or not?

  Example inputs:
  ```hcl
      database_collection = {
      name       = "database_mongoDb_collections"
      throughput = 400

      collections = {
        "collection" = {
          name                = "MongoDBcollection"
          default_ttl_seconds = "3600"
          shard_key           = "_id"
          throughput          = 400

          index = {
            keys   = ["_id"]
            unique = true
          }
        }
      }
    }
  ```
  DESCRIPTION

  validation {
    condition = alltrue(
      [
        for db in var.mongo_databases : can(regex("^[^/\\.\"$*<>:|?]*$", db.name))
    ])
    error_message = "The name field cannot contain the characters /\\.\"$*<>:|?"
  }

  validation {
    condition = alltrue(
      [
        for db in var.mongo_databases : length(db.name) <= 64
      ]
    )
    error_message = "The 'name' field must be 64 characters or less."
  }

  validation {
    condition = length(
      [
        for db_key, db_params in var.mongo_databases : db_params.name
        ]) == length(distinct(
        [
          for db_key, db_params in var.mongo_databases : db_params.name
      ])
    )
    error_message = "The 'name' in the sql database value must be unique."
  }

  validation {
    condition = alltrue(
      [for key, value in var.mongo_databases : value.throughput != null ? value.throughput >= 400 : true]
    )
    error_message = "The 'throughput' in the database value must be greater than or equal to 400 if specified."
  }

  validation {
    condition = alltrue(
      [
        for key, value in var.mongo_databases :
        try(value.autoscale_settings.max_throughput, null) != null ? value.autoscale_settings.max_throughput >= 1000 && value.autoscale_settings.max_throughput <= 1000000 : true
      ]
    )
    error_message = "The 'max_throughput' in the autoscale_settings value must be between 1000 and 1000000 if specified."
  }

  validation {
    condition = alltrue(
      [
        for key, value in var.mongo_databases :
        try(value.autoscale_settings.max_throughput, null) != null ? value.autoscale_settings.max_throughput % 1000 == 0 : true
      ]
    )
    error_message = "The 'max_throughput' in the autoscale_settings value must be a multiple of 1000 if specified."
  }

  validation {
    condition = alltrue(
      [
        for key, value in var.mongo_databases :
        try(value.autoscale_settings.max_throughput, null) != null && value.throughput != null ? false : true
      ]
    )
    error_message = "The 'throughput' and 'autoscale_settings.max_throughput' cannot be specified at the same time at database level."
  }

  validation {
    condition = alltrue(
      [
        for db in var.mongo_databases :
        db.collections != null && alltrue([
          for collection in db.collections :
          length(collection.name) <= 120
        ])
      ]
    )
    error_message = "The collection name must not exceed 120 characters."
  }
  validation {
    condition = alltrue(
      flatten([
        for db_key, db_params in var.mongo_databases :
        [
          for collection_key, collection_params in db_params.collections :
          collection_params.throughput != null ? collection_params.throughput >= 400 : true
        ]
      ])
    )
    error_message = "The 'throughput' value at the collection level must be greater than or equal to 400 if specified."
  }

  validation {
    condition = alltrue(
      [
        for db_key, db_value in var.mongo_databases :
        alltrue([
          for collection_key, collection_value in db_value.collections :
          try(collection_value.autoscale_settings.max_throughput, null) != null ? collection_value.autoscale_settings.max_throughput >= 1000 && collection_value.autoscale_settings.max_throughput <= 1000000 : true
        ])
      ]
    )
    error_message = "The 'max_throughput' in the collection value must be between 1000 and 1000000 if specified."
  }

  validation {
    condition = alltrue(
      [
        for db_key, db_value in var.mongo_databases :
        alltrue([
          for collection_key, collection_value in db_value.collections :
          try(collection_value.autoscale_settings.max_throughput, null) != null && collection_value.throughput != null ? false : true
        ])
      ]
    )
    error_message = "The 'throughput' and 'autoscale_settings.max_throughput' cannot be specified at the same time at collection level."
  }

  validation {
    condition = alltrue(
      [
        for db_key, db_value in var.mongo_databases :
        alltrue([
          for collection_key, collection_value in db_value.collections :
          try(collection_value.autoscale_settings.max_throughput, null) != null ? collection_value.autoscale_settings.max_throughput % 1000 == 0 : true
        ])
      ]
    )
    error_message = "The 'max_throughput' in the autoscale_settings value must be a multiple of 1000 if specified at collection level."
  }
}
