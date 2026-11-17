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

locals {
  # The collection settings the AzureRM provider sent. The indexes are listed by their first key, with the `_id`
  # index that Azure requires, and the time-to-live index on `_ts` last. Settings that do not apply are null, and
  # are not sent.
  mongo_collection_indexes = {
    for key, collection in local.mongodb_collections : key => merge(
      { "_id" = ["_id"] },
      collection.collection_params.index == null ? {} : { (collection.collection_params.index.keys[0]) = collection.collection_params.index.keys },
    )
  }
  mongo_collection_resources = {
    for key, collection in local.mongodb_collections : key => {
      id = collection.collection_name
      indexes = concat(
        [
          for first_key in sort(keys(local.mongo_collection_indexes[key])) : {
            key = {
              keys = local.mongo_collection_indexes[key][first_key]
            }
            options = {
              expireAfterSeconds = null
              unique             = first_key == "_id" ? true : try(collection.collection_params.index.unique, false)
            }
          }
        ],
        collection.collection_params.default_ttl_seconds == null ? [] : [
          {
            key = {
              keys = ["_ts"]
            }
            options = {
              expireAfterSeconds = tonumber(collection.collection_params.default_ttl_seconds)
              unique             = null
            }
          }
        ],
      )
      shardKey = collection.collection_params.shard_key == null ? null : {
        (collection.collection_params.shard_key) = "Hash"
      }
    }
  }
}
