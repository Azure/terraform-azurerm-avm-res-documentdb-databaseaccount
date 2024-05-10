variable "geo_locations" {
  type = set(object({
    location          = string
    failover_priority = number
    zone_redundant    = optional(bool, true)
  }))
  default     = null
  description = <<DESCRIPTION
  Default to the region where the account was deployed with zone redundant enabled. Specifies a geo_location resource, used to define where data should be replicated with the failover_priority 0 specifying the primary location.

  - `location`          - (Required) - The name of the Azure location where the CosmosDB Account is being created.
  - `failover_priority` - (Required) - The failover priority of the region. A failover priority of 0 indicates a write region.
  - `zone_redundant`    - (Optional) - Defaults to `true`. Whether or not the region is zone redundant.
  
  Example inputs:
  ```hcl
  geo_locations = [
    {
      location          = "eastus"
      failover_priority = 0
      zone_redundant    = true
    },
    {
      location          = "westus"
      failover_priority = 1
      zone_redundant    = true
    }
  ]
  ```
  DESCRIPTION
}

variable "local_authentication_disabled" {
  type        = bool
  nullable    = false
  default     = false
  description = "Defaults to `false`. Ignored for non SQL APIs accounts. Disable local authentication and ensure only MSI and AAD can be used exclusively for authentication. Can be set only when using the SQL API."
}

variable "analytical_storage_enabled" {
  type        = bool
  nullable    = false
  default     = false
  description = "Defaults to `false`. Enable Analytical Storage option for this Cosmos DB account. Enabling and then disabling analytical storage forces a new resource to be created."
}

variable "access_key_metadata_writes_enabled" {
  type        = bool
  default     = false
  description = "Defaults to `false`. Is write operations on metadata resources (databases, containers, throughput) via account keys enabled?"
}

variable "automatic_failover_enabled" {
  type        = bool
  nullable    = false
  default     = true
  description = "Defaults to `true`. Enable automatic failover for this Cosmos DB account."
}

variable "free_tier_enabled" {
  type        = bool
  nullable    = false
  default     = false
  description = "Defaults to `false`. Enable the Free Tier pricing option for this Cosmos DB account. Defaults to false. Changing this forces a new resource to be created."
}

variable "multiple_write_locations_enabled" {
  type        = bool
  nullable    = false
  default     = false
  description = "Defaults to `false`. Ignored when `backup.type` is `Continuous`. Enable multi-region writes for this Cosmos DB account."
}

variable "partition_merge_enabled" {
  type        = bool
  nullable    = false
  default     = false
  description = "Defaults to `false`. Is partition merge on the Cosmos DB account enabled?"
}

variable "consistency_policy" {
  type = object({
    max_interval_in_seconds = optional(number, 5)
    max_staleness_prefix    = optional(number, 100)
    consistency_level       = optional(string, "ConsistentPrefix")
  })
  nullable    = false
  default     = {}
  description = <<DESCRIPTION
  Defaults to `{}`. Used to define the consistency policy for this CosmosDB account

  - `consistency_level`       - (Optional) - Defaults to `ConsistentPrefix`. The Consistency Level to use for this CosmosDB Account - can be either `BoundedStaleness`, `Eventual`, `Session`, `Strong` or `ConsistentPrefix`.
  - `max_interval_in_seconds` - (Optional) - Defaults to `5`. Used when `consistency_level` is set to `BoundedStaleness`. When used with the Bounded Staleness consistency level, this value represents the time amount of staleness (in seconds) tolerated. The accepted range for this value is `5` - `86400` (1 day).
  - `max_staleness_prefix`    - (Optional) - Defaults to `100`. Used when `consistency_level` is set to `BoundedStaleness`. When used with the Bounded Staleness consistency level, this value represents the number of stale requests tolerated. The accepted range for this value is `10` – `2147483647`

  Example inputs:
  ```hcl
  consistency_policy = {
    consistency_level       = "ConsistentPrefix"
    max_interval_in_seconds = 10
    max_interval_in_seconds = 100
  }
  ```
  DESCRIPTION

  validation {
    condition     = var.consistency_policy.consistency_level == "ConsistentPrefix" ? var.consistency_policy.max_interval_in_seconds >= 5 && var.consistency_policy.max_interval_in_seconds <= 86400 : true
    error_message = "The 'max_interval_in_seconds' value must be between 5 and 86400 when 'ConsistentPrefix' consistency level is set."
  }

  validation {
    condition     = var.consistency_policy.consistency_level == "ConsistentPrefix" ? var.consistency_policy.max_staleness_prefix >= 10 && var.consistency_policy.max_staleness_prefix <= 2147483647 : true
    error_message = "The 'max_staleness_prefix' value must be between 10 and 2147483647 when 'ConsistentPrefix' consistency level is set."
  }

  validation {
    condition     = contains(["BoundedStaleness", "Eventual", "Session", "Strong", "ConsistentPrefix"], var.consistency_policy.consistency_level)
    error_message = "The 'consistency_level' value must be one of 'BoundedStaleness', 'Eventual', 'Session', 'Strong' or 'ConsistentPrefix'."
  }
}

variable "backup" {
  type = object({
    retention_in_hours  = optional(number, 8)
    interval_in_minutes = optional(number, 240)
    storage_redundancy  = optional(string, "Geo")
    type                = optional(string, "Continuous")
    tier                = optional(string, "Continuous30Days")
  })
  nullable    = false
  default     = {}
  description = <<DESCRIPTION
  Defaults to `{}`. Configures the backup policy for this Cosmos DB account.

  - `type`                - (Optional) - Defaults to `Continuous`. The type of the backup. Possible values are `Continuous` and `Periodic`
  - `tier`                - (Optional) - Defaults to `Continuous30Days`. Used when `type` is set to `Continuous`. The continuous backup tier. Possible values are `Continuous7Days` and `Continuous30Days`.
  - `interval_in_minutes` - (Optional) - Defaults to `240`. Used when `type` is set to `Periodic`. The interval in minutes between two backups. Possible values are between `60` and `1440`
  - `retention_in_hours`  - (Optional) - Defaults to `8`. Used when `type` is set to `Periodic`. The time in hours that each backup is retained. Possible values are between `8` and `720`
  - `storage_redundancy`  - (Optional) - Defaults to `Geo`. Used when `type` is set to `Periodic`. The storage redundancy is used to indicate the type of backup residency. Possible values are `Geo`, `Local` and `Zone`

  Example inputs:
  ```hcl
  # For Continuous Backup
  backup = {
    type = "Continuous"
    tier = "Continuous30Days"
  }

  # For Periodic Backup
  backup = {
    type                = "Periodic"
    storage_redundancy  = "Geo"
    interval_in_minutes = 240
    retention_in_hours  = 8
  }
  ```
  DESCRIPTION

  validation {
    condition     = var.backup.type == "Continuous" ? contains(["Continuous7Days", "Continuous30Days"], var.backup.tier) : true
    error_message = "The 'tier' value must be 'Continuous7Days' or 'Continuous30Days' when type is 'Continuous'."
  }

  validation {
    condition     = var.backup.type == "Periodic" ? contains(["Geo", "Zone", "Local"], var.backup.storage_redundancy) : true
    error_message = "The 'storage_redundancy' value must be 'Geo', 'Zone' or 'Local' when type is 'Periodic'."
  }

  validation {
    condition     = var.backup.type == "Periodic" ? var.backup.interval_in_minutes >= 60 && var.backup.interval_in_minutes <= 1440 : true
    error_message = "The 'interval_in_minutes' value must be between 60 and 1440 when type is 'Periodic'."
  }

  validation {
    condition     = var.backup.type == "Periodic" ? var.backup.retention_in_hours >= 8 && var.backup.retention_in_hours <= 720 : true
    error_message = "The 'retention_in_hours' value must be between 8 and 720 when type is 'Periodic'."
  }
}

variable "capacity" {
  type = object({
    total_throughput_limit = optional(number, -1)
  })
  nullable    = false
  default     = {}
  description = <<DESCRIPTION
  Defaults to `{}`. Configures the throughput limit for this Cosmos DB account.

  - `total_throughput_limit` - (Optional) - Defaults to `-1`. The total throughput limit imposed on this Cosmos DB account (RU/s). Possible values are at least -1. -1 means no limit.

  Example inputs:
  ```hcl
  capacity = {
    total_throughput_limit = -1
  }
  ```
  DESCRIPTION

  validation {
    condition     = var.capacity.total_throughput_limit >= -1
    error_message = "The 'total_throughput_limit' value must be at least '-1'."
  }
}

variable "analytical_storage_config" {
  type = object({
    schema_type = string
  })
  default     = null
  description = <<DESCRIPTION
  Defaults to `null`. Configuration related to the analytical storage of this account

  - `schema_type` - (Required) - The schema type of the Analytical Storage for this Cosmos DB account. Possible values are FullFidelity and WellDefined.

  Example inputs:
  ```hcl
  analytical_storage_config = {
    schema_type = "WellDefined"
  }
  ```
  DESCRIPTION

  validation {
    condition     = var.analytical_storage_config != null ? contains(["WellDefined", "FullFidelity"], var.analytical_storage_config.schema_type) : true
    error_message = "The 'schema_type' value must be 'WellDefined' or 'FullFidelity'."
  }
}

variable "cors_rule" {
  type = object({
    allowed_headers    = set(string)
    allowed_methods    = set(string)
    allowed_origins    = set(string)
    exposed_headers    = set(string)
    max_age_in_seconds = optional(number, null)
  })
  default     = null
  description = <<DESCRIPTION
  Defaults to `null`. Configures the CORS rule for this Cosmos DB account.

  - `allowed_headers`    - (Required) - A list of headers that are allowed to be a part of the cross-origin request.
  - `allowed_methods`    - (Required) - A list of HTTP headers that are allowed to be executed by the origin. Valid options are `DELETE`, `GET`, `HEAD`, `MERGE`, `POST`, `OPTIONS`, `PUT` or `PATCH`.
  - `allowed_origins`    - (Required) - A list of origin domains that will be allowed by CORS.
  - `exposed_headers`    - (Required) - A list of response headers that are exposed to CORS clients.
  - `max_age_in_seconds` - (Optional) - Defaults to `null`. The number of seconds the client should cache a preflight response. Possible values are between `1` and `2147483647`

  Example inputs:
  ```hcl
  cors_rule = {
    allowed_headers = ["Custom-Header"]
    allowed_methods = ["POST"]
    allowed_origins = ["microsoft.com"]
    exposed_headers = ["Custom-Header"]
    max_age_in_seconds = 100
  }
  ```
  DESCRIPTION

  validation {
    condition = var.cors_rule != null ? alltrue([
      for value in var.cors_rule.allowed_methods :
      contains(["DELETE", "GET", "HEAD", "MERGE", "POST", "OPTIONS", "PUT", "PATCH"], value)
    ]) : true
    error_message = "The 'allowed_methods' value must be 'DELETE', 'GET', 'HEAD', 'MERGE', 'POST', 'OPTIONS', 'PUT' or 'PATCH'."
  }

  validation {
    condition     = var.cors_rule != null ? var.cors_rule.max_age_in_seconds == null || var.cors_rule.max_age_in_seconds >= 1 && var.cors_rule.max_age_in_seconds <= 2147483647 : true
    error_message = "The 'max_age_in_seconds' value if set must be between 1 and 2147483647."
  }
}

variable "capabilities" {
  type = set(object({
    name = string
  }))
  nullable    = false
  default     = []
  description = <<DESCRIPTION
  Defaults to `[]`. The capabilities which should be enabled for this Cosmos DB account.

  - `name` - (Required) - The capability to enable - Possible values are `AllowSelfServeUpgradeToMongo36`, `DisableRateLimitingResponses`, `EnableAggregationPipeline`, `EnableCassandra`, `EnableGremlin`, `EnableMongo`, `EnableMongo16MBDocumentSupport`, `EnableMongoRetryableWrites`, `EnableMongoRoleBasedAccessControl`, `EnablePartialUniqueIndex`, `EnableServerless`, `EnableTable`, `EnableTtlOnCustomPath`, `EnableUniqueCompoundNestedDocs`, `MongoDBv3.4` and `mongoEnableDocLevelTTL`.

  Example inputs:
  ```hcl
  capabilities = [
    {
      name = "DisableRateLimitingResponses"
    }
  ]
  ```
  DESCRIPTION

  validation {
    condition = alltrue([
      for capability in var.capabilities :
      contains(["AllowSelfServeUpgradeToMongo36", "DisableRateLimitingResponses", "EnableAggregationPipeline", "EnableCassandra", "EnableGremlin", "EnableMongo", "EnableMongo16MBDocumentSupport", "EnableMongoRetryableWrites", "EnableMongoRoleBasedAccessControl", "EnablePartialUniqueIndex", "EnableServerless", "EnableTable", "EnableTtlOnCustomPath", "EnableUniqueCompoundNestedDocs", "MongoDBv3.4", "mongoEnableDocLevelTTL"], capability.name)
    ])
    error_message = "The 'name' value must be one of 'AllowSelfServeUpgradeToMongo36', 'DisableRateLimitingResponses', 'EnableAggregationPipeline', 'EnableCassandra', 'EnableGremlin', 'EnableMongo', 'EnableMongo16MBDocumentSupport', 'EnableMongoRetryableWrites', 'EnableMongoRoleBasedAccessControl', 'EnablePartialUniqueIndex', 'EnableServerless', 'EnableTable', 'EnableTtlOnCustomPath', 'EnableUniqueCompoundNestedDocs', 'MongoDBv3.4' or 'mongoEnableDocLevelTTL'."
  }
}