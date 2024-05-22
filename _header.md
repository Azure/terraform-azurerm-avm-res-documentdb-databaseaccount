# Terraform Azure Cosmos DB Module

This Terraform module is designed to create Azure Cosmos DB accounts, its related resources and APIs.

> [!WARNING]
> Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. A module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>

## Features

* Creation of accounts with NoSQL API with its databases and containers.
* EntraID authentication instead of access keys
* Support for customer-managed keys.
* Enable private endpoint, providing secure access over a private network.
* Enable diagnostic settings.
* Creation of role assignments
* Enable locks
* Enable managed identities both system and user assigned ones.

## Limitations

* The module does not support auto rotation of Customer Managed keys (CosmosDB doesn't support it yet)
* The module does not support the Gremlin API yet
* The module does not support the MongoDB API yet
* The module does not support the Table API yet
* The module does not support the Cassandra API yet

## Examples
* [Use only defaults values](examples/default/main.tf)
* [Specifying all possible parameters at account level](examples/max-account/main.tf)
* [Creation of sql api](examples/sql/main.tf)
* [Creation of a serverless account](examples/serverless/main.tf)
* [Customer managed key pinning to a specific key version](examples/cmk-pin-key-version/main.tf)
* [Enable managed identities](examples/managed-identities/main.tf)
* [Enable private endpoints with auto management of dns records](examples/private-endpoints-managed-dns-records/main.tf)
* [Enable private endpoints with auto management of dns records](examples/private-endpoints-unmanaged-dns-records/main.tf)
* [Restrict public network access with access control list and service endpoints](examples/public-restricted-access/main.tf)
