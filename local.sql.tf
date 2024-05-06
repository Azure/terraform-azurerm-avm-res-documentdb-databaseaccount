locals {
  normalized_sql_databases = {
    for db_key, db_params in var.sql_databases : coalesce(db_params.name, db_key) => db_params
  }

  flatten_sql_containers = flatten(
    [ 
      for db_name, db_params in local.normalized_sql_databases : 
      [
        for container_key, container_params in db_params.containers : {
          db_name = db_name
          container_params = container_params
          container_name = coalesce(container_params.name, container_key)
        }
      ]
    ]
  )

  sql_containers = {
    for sql_container in local.flatten_sql_containers : 
    "${sql_container.db_name}|${sql_container.container_name}" => sql_container
  }
}