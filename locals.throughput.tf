locals {
  # The throughput of every database, container, collection and graph, keyed by kind and by the key of the resource.
  throughput = merge(
    {
      for key, database in var.sql_databases : "sql_database|${key}" => {
        max_throughput = try(database.autoscale_settings.max_throughput, null)
        throughput     = database.throughput
      }
    },
    {
      for key, container in local.sql_containers : "sql_container|${key}" => {
        max_throughput = try(container.container_params.autoscale_settings.max_throughput, null)
        throughput     = container.container_params.throughput
      }
    },
    {
      for key, database in var.mongo_databases : "mongo_database|${key}" => {
        max_throughput = try(database.autoscale_settings.max_throughput, null)
        throughput     = database.throughput
      }
    },
    {
      for key, collection in local.mongodb_collections : "mongo_collection|${key}" => {
        max_throughput = try(collection.collection_params.autoscale_settings.max_throughput, null)
        throughput     = collection.collection_params.throughput
      }
    },
    {
      for key, database in var.gremlin_databases : "gremlin_database|${key}" => {
        max_throughput = try(database.autoscale_settings.max_throughput, null)
        throughput     = database.throughput
      }
    },
    {
      for key, graph in local.gremlin_graphs : "gremlin_graph|${key}" => {
        max_throughput = try(graph.graph_params.autoscale_settings.max_throughput, null)
        throughput     = graph.graph_params.throughput
      }
    },
  )
  # The `options` sent when a resource is created, as the AzureRM provider sent them.
  throughput_options = {
    for key, throughput in local.throughput : key => {
      for name, value in {
        autoscaleSettings = throughput.max_throughput == null ? null : { maxThroughput = throughput.max_throughput }
        throughput        = throughput.throughput
      } : name => value if value != null
    }
  }
  # The throughput settings sent when the throughput changes, as the AzureRM provider sent them. Autoscale wins
  # when both are set.
  throughput_resources = {
    for key, throughput in local.throughput : key => {
      for name, value in {
        autoscaleSettings = throughput.max_throughput == null ? null : { maxThroughput = throughput.max_throughput }
        throughput        = throughput.max_throughput == null ? throughput.throughput : null
      } : name => value if value != null
    } if throughput.max_throughput != null || throughput.throughput != null
  }
}
