locals {
  flatten_mongodb_collections = flatten(
    [
      for db_name, db_params in var.mongo_databases :
      [
        for collection_key, collection_params in db_params.collections : {
          db_name           = db_name
          collection_params = collection_params
          collection_name   = collection_params.name
        }
      ]
    ]
  )
  mongodb_collections = {
    for mongodb_collection in local.flatten_mongodb_collections :
    "${mongodb_collection.db_name}|${mongodb_collection.collection_name}" => mongodb_collection
  }
}
