locals {
  role_definition_resource_substring = "providers/Microsoft.Authorization/roleDefinitions"

  flatten_queue_role_assignments = flatten([
    for queue_name, queue_params in var.queues : [
      for role_key, role_params in queue_params.role_assignments : {
        role_key    = role_key
        queue_name  = queue_name
        role_params = role_params
        scope_type  = local.queue_scope_type
      }
    ]
  ])

  queue_role_assignments = {
    for queue_role in local.flatten_queue_role_assignments :
    "${queue_role.scope_type}|${queue_role.role_key}|${queue_role.queue_name}" => queue_role
  }

  flatten_topic_role_assignments = flatten([
    for topic_name, topic_params in local.normalized_topics : [
      for role_key, role_params in topic_params.role_assignments : {
        role_key    = role_key
        topic_name  = topic_name
        role_params = role_params
        scope_type  = local.topic_scope_type
      }
    ]
  ])

  topic_role_assignments = {
    for topic_role in local.flatten_topic_role_assignments :
    "${topic_role.scope_type}|${topic_role.role_key}|${topic_role.topic_name}" => topic_role
  }

  namespace_role_assignments = {
    for role_key, role_params in var.role_assignments :
    "${local.namespace_scope_type}|${role_key}" => {
      role_params = role_params
      scope_type  = local.namespace_scope_type
    }
  }

  flatten_pe_role_assignments = flatten([
    for pe_name, pe_params in local.normalized_private_endpoints : [
      for role_key, role_params in pe_params.role_assignments : {
        role_key    = role_key
        pe_name     = pe_name
        role_params = role_params
        scope_type  = local.private_endpoint_scope_type
      }
    ]
  ])

  pe_role_assignments = {
    for pe_role in local.flatten_pe_role_assignments :
    "${pe_role.scope_type}|${pe_role.role_key}" => pe_role
  }

  total_role_assignments = merge(local.namespace_role_assignments, local.queue_role_assignments, local.topic_role_assignments, local.pe_role_assignments)
}
