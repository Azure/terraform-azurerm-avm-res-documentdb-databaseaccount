locals {
  flattened_gremlin_graphs = flatten(
    [
      for db_name, db_params in var.gremlin_databases :
      [
        for graph_key, graph_params in db_params.graphs : {
          db_name      = db_name
          graph_params = graph_params
          graph_name   = graph_params.name
        }
      ]
    ]
  )
  gremlin_graphs = {
    for gremlin_graph in local.flattened_gremlin_graphs :
    "${gremlin_graph.db_name}|${gremlin_graph.graph_name}" => gremlin_graph
  }
}

locals {
  # The graph settings the AzureRM provider sent. Settings that do not apply are null, and are not sent.
  gremlin_graph_resources = {
    for key, graph in local.gremlin_graphs : key => {
      analyticalStorageTtl = coalesce(graph.graph_params.analytical_storage_ttl, 0) != 0 ? graph.graph_params.analytical_storage_ttl : null
      conflictResolutionPolicy = graph.graph_params.conflict_resolution_policy == null ? null : {
        conflictResolutionPath      = graph.graph_params.conflict_resolution_policy.conflict_resolution_path == null ? "" : graph.graph_params.conflict_resolution_policy.conflict_resolution_path
        conflictResolutionProcedure = graph.graph_params.conflict_resolution_policy.conflict_resolution_procedure == null ? "" : graph.graph_params.conflict_resolution_policy.conflict_resolution_procedure
        mode                        = graph.graph_params.conflict_resolution_policy.mode
      }
      defaultTtl = coalesce(graph.graph_params.default_ttl, 0) != 0 ? graph.graph_params.default_ttl : null
      id         = graph.graph_params.name
      indexingPolicy = graph.graph_params.index_policy == null ? null : {
        automatic = graph.graph_params.index_policy.automatic
        compositeIndexes = [
          for composite_index in graph.graph_params.index_policy.composite_index == null ? [] : graph.graph_params.index_policy.composite_index : [
            for index in composite_index.index : {
              order = lower(index.order)
              path  = index.path
            }
          ]
        ]
        # Azure always excludes the `_etag` property, and returns it with the excluded paths.
        excludedPaths = [for path in distinct(concat(graph.graph_params.index_policy.excluded_paths, ["/\"_etag\"/?"])) : { path = path }]
        includedPaths = [for path in graph.graph_params.index_policy.included_paths : { path = path }]
        indexingMode  = lower(graph.graph_params.index_policy.indexing_mode)
        spatialIndexes = graph.graph_params.index_policy.spatial_index == null || length(coalesce(graph.graph_params.index_policy.spatial_index, [])) == 0 ? null : [
          for spatial_index in graph.graph_params.index_policy.spatial_index == null ? [] : graph.graph_params.index_policy.spatial_index : {
            path  = spatial_index.path
            types = ["LineString", "MultiPolygon", "Point", "Polygon"]
          }
        ]
      }
      partitionKey = {
        kind    = "Hash"
        paths   = [graph.graph_params.partition_key_path]
        version = graph.graph_params.partition_key_version == null ? null : tonumber(graph.graph_params.partition_key_version)
      }
      uniqueKeyPolicy = graph.graph_params.unique_key == null ? null : {
        uniqueKeys = [{ paths = graph.graph_params.unique_key.paths }]
      }
    }
  }
}
