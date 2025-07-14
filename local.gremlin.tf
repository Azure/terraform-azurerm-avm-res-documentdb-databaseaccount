locals {
  flattened_gremlin_graphs = flatten(
    [
      for db_name, db_params in var.gremlin_databases:
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
