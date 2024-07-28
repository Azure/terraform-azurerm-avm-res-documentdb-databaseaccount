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
