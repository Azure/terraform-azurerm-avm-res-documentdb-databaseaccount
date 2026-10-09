output "cassandra_keyspaces" {
  description = "A map of the Cassandra keyspaces created, with each keyspace's resource ID and table IDs, keyed by the input maps."
  value = {
    for keyspace_key, keyspace in azapi_resource.cassandra_keyspaces : keyspace_key => {
      id = keyspace.id
      tables = {
        for table_key, table in azapi_resource.cassandra_tables :
        local.cassandra_tables[table_key].table_key => table.id
        if local.cassandra_tables[table_key].keyspace_key == keyspace_key
      }
    }
  }
}
