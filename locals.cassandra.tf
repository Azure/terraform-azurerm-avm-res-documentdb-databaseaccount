locals {
  flatten_cassandra_tables = flatten([
    for keyspace_key, keyspace in var.cassandra_keyspaces : [
      for table_key, table in keyspace.tables : {
        keyspace_key = keyspace_key
        table        = table
        table_key    = table_key
      }
    ]
  ])
  cassandra_tables = {
    for table in local.flatten_cassandra_tables :
    jsonencode([table.keyspace_key, table.table_key]) => table
  }
}
