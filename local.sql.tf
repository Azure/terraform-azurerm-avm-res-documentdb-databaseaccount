locals {
  flatten_sql_container_functions = flatten(
    [
      for sql_container_key, sql_container in local.sql_containers :
      [
        for function_key, function_params in sql_container.container_params.functions : {
          function_params = function_params
          container_key   = sql_container_key
          function_name   = function_params.name
          db_name         = sql_container.db_name
          container_name  = sql_container.container_name
        }
      ]
    ]
  )
  flatten_sql_container_stored_procedures = flatten(
    [
      for sql_container_key, sql_container in local.sql_containers :
      [
        for stored_key, stored_params in sql_container.container_params.stored_procedures : {
          stored_params  = stored_params
          container_key  = sql_container_key
          stored_name    = stored_params.name
          db_name        = sql_container.db_name
          container_name = sql_container.container_name
        }
      ]
    ]
  )
  flatten_sql_container_triggers = flatten(
    [
      for sql_container_key, sql_container in local.sql_containers :
      [
        for trigger_key, trigger_params in sql_container.container_params.triggers : {
          trigger_params = trigger_params
          container_key  = sql_container_key
          trigger_name   = trigger_params.name
          db_name        = sql_container.db_name
          container_name = sql_container.container_name
        }
      ]
    ]
  )
  flatten_sql_containers = flatten(
    [
      for db_name, db_params in var.sql_databases :
      [
        for container_key, container_params in db_params.containers : {
          db_name          = db_name
          container_params = container_params
          container_name   = container_params.name
        }
      ]
    ]
  )
  sql_container_functions = {
    for sql_container_function in local.flatten_sql_container_functions :
    "${sql_container_function.db_name}|${sql_container_function.container_name}|${sql_container_function.function_name}" => sql_container_function
  }
  sql_container_stored_procedures = {
    for sql_container_stored_procedure in local.flatten_sql_container_stored_procedures :
    "${sql_container_stored_procedure.db_name}|${sql_container_stored_procedure.container_name}|${sql_container_stored_procedure.stored_name}" => sql_container_stored_procedure
  }
  sql_container_triggers = {
    for sql_container_trigger in local.flatten_sql_container_triggers :
    "${sql_container_trigger.db_name}|${sql_container_trigger.container_name}|${sql_container_trigger.trigger_name}" => sql_container_trigger
  }
  sql_containers = {
    for sql_container in local.flatten_sql_containers :
    "${sql_container.db_name}|${sql_container.container_name}" => sql_container
  }
}

locals {
  # The container settings the AzureRM provider sent. Settings that do not apply are null, and are not sent.
  sql_container_resources = {
    for key, container in local.sql_containers : key => {
      analyticalStorageTtl = coalesce(container.container_params.analytical_storage_ttl, 0) != 0 ? container.container_params.analytical_storage_ttl : null
      conflictResolutionPolicy = container.container_params.conflict_resolution_policy == null ? null : {
        conflictResolutionPath      = container.container_params.conflict_resolution_policy.mode == "LastWriterWins" && container.container_params.conflict_resolution_policy.conflict_resolution_path != null ? container.container_params.conflict_resolution_policy.conflict_resolution_path : ""
        conflictResolutionProcedure = container.container_params.conflict_resolution_policy.mode == "Custom" ? "dbs/{${container.db_name}}/colls/{${container.container_name}}/sprocs/{${container.container_params.conflict_resolution_policy.conflict_resolution_procedure}}" : ""
        mode                        = container.container_params.conflict_resolution_policy.mode
      }
      defaultTtl = coalesce(container.container_params.default_ttl, 0) != 0 ? container.container_params.default_ttl : null
      id         = container.container_name
      indexingPolicy = container.container_params.indexing_policy == null ? null : {
        compositeIndexes = [
          for composite_index in container.container_params.indexing_policy.composite_indexes : [
            for index in composite_index.indexes : {
              order = lower(index.order)
              path  = index.path
            }
          ]
        ]
        # Azure always excludes the `_etag` property, and returns it with the excluded paths.
        excludedPaths = length(container.container_params.indexing_policy.excluded_paths) == 0 ? null : [
          for path in distinct(concat([for excluded_path in container.container_params.indexing_policy.excluded_paths : excluded_path.path], ["/\"_etag\"/?"])) : { path = path }
        ]
        includedPaths = length(container.container_params.indexing_policy.included_paths) == 0 ? null : [
          for included_path in container.container_params.indexing_policy.included_paths : { path = included_path.path }
        ]
        indexingMode = lower(container.container_params.indexing_policy.indexing_mode)
        spatialIndexes = length(container.container_params.indexing_policy.spatial_indexes) == 0 ? null : [
          for spatial_index in container.container_params.indexing_policy.spatial_indexes : {
            path  = spatial_index.path
            types = ["LineString", "MultiPolygon", "Point", "Polygon"]
          }
        ]
      }
      partitionKey = {
        kind    = "Hash"
        paths   = container.container_params.partition_key_paths
        version = container.container_params.partition_key_version
      }
      uniqueKeyPolicy = length(container.container_params.unique_keys) == 0 ? null : {
        uniqueKeys = [for unique_key in container.container_params.unique_keys : { paths = tolist(unique_key.paths) }]
      }
    }
  }
}
