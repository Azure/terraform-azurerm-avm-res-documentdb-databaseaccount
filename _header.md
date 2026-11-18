# Terraform Azure Cosmos DB Module

This Terraform module is designed to create Azure Cosmos DB accounts, its related resources and APIs.

> [!WARNING]
> Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. A module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>

## Upgrading from 0.12.x or earlier

The account and the resources around it are now AzAPI resources, and the module no longer uses the AzureRM provider. `moved` blocks carry the account, its databases, containers, collections, graphs, stored procedures, triggers and user-defined functions, the dedicated gateway, the locks, diagnostic settings, role assignments and private endpoints to their new addresses in the state, so nothing is recreated. Terraform 1.16 or later is required.

1. `resource_group_name` is replaced by `parent_id`, the resource ID of the resource group. Spell the resource group name exactly as you did in `resource_group_name`, including its case, for example by passing the resource group's `id`. A different spelling plans replacements.
1. Keep the AzureRM provider's `provider` block in your root module until the upgrade has been applied. Terraform needs it to remove the application security group associations from the state.
1. A `ReadOnly` lock blocks the upgrade, because the account, the resources under it and the private endpoints are updated, and the keys are read. With your current version, change it to `CanNotDelete` or remove it before upgrading, and restore it afterwards.
1. Set `avm_managed_migration_enabled = true` for the upgrade apply. The module then reads the keys and connection strings during plan, so resources that use the `cosmosdb_keys` or connection string outputs are not changed. It also imports the private DNS zone groups that the private endpoints had, which are now separate resources, rather than failing with `Resource already exists`. Remove the flag after the upgrade. Leave it unset on a new deployment, because a zone group that does not exist yet cannot be imported.
1. `principal_type`, `condition`, `condition_version` and `description` in `role_assignments` and `private_endpoints[*].role_assignments` now reach Azure. Earlier versions accepted them but never sent them. Role assignments that set them are updated in place, not recreated. `principal_type` changes nothing if it matches the principal's actual type. `principal_type` must be `User`, `Group` or `ServicePrincipal`, and `condition_version` requires `condition`.
1. Cross-tenant role assignments, which set `delegated_managed_identity_resource_id`, need extra steps. The AzureRM provider stored their ID with a `|<tenant-id>` suffix that the `moved` block cannot convert. Before planning, remove each one from the state, then import it at its new address with an `import` block in your root module:

   ```pwsh
   terraform state rm 'module.<module-name>.azurerm_role_assignment.this["<key>"]'
   ```

   ```hcl
   import {
     to = module.<module-name>.azapi_resource.role_assignments["<key>"]
     id = "<role assignment resource ID, without the |<tenant-id> suffix>"
   }
   ```

1. Run `terraform init -upgrade`, then `terraform plan`. The plan must not destroy or replace anything, except the AVM telemetry deployment, whose name includes the module version. It updates the moved resources in place with the same settings. Outputs stay known in this plan, except `read_endpoints` and `write_endpoints`. The plan also adds:
   - `azapi_resource_action.secrets`, which reads the keys and connection strings;
   - an `azapi_update_resource` for the throughput of each database, container, collection and graph that sets one, which sends the throughput that is already set;
   - a `random_uuid` for each role assignment, which only exists in the state. The assignments keep their names;
   - a `time_sleep` for each lock, which pauses for 30 seconds when the lock is removed;
   - the imported private DNS zone groups, when `avm_managed_migration_enabled` is set.

   The application security group associations are removed from the state without being changed in Azure. Application security groups are now set on the private endpoints.
1. Apply the plan. Later plans report no changes, except that, when telemetry is enabled, each plan updates the AVM telemetry deployment to record the apply.

Other changes:

- `resource_types`, `retry`, `timeouts` and `ignore_body_changes` cover all the module's resources.
- `lock` accepts `notes` and `role_assignments` accepts `name`, also within `private_endpoints`. `private_endpoints[*].ip_configurations` accepts `member_name`, and `private_endpoints[*].resource_group_name` accepts a name or a resource ID. The resource IDs in `private_endpoints` are validated during plan.
- The `resource` output keeps the attribute names of the `azurerm_cosmosdb_account` resource. `resource_diagnostic_settings` returns the diagnostic settings' resource IDs rather than the `<account ID>|<name>` IDs of the AzureRM provider, and `sql_databases` now lists the functions of each container, which earlier versions left empty.
- Role names are matched, ignoring case, against the role definitions that can be assigned in the resource group, and an unknown name fails during plan. A role definition ID that starts with `/providers/` no longer replaces its role assignment on every apply.
- The keys and connection strings are read when the account is created, rather than on every refresh, so a `ReadOnly` lock on the account no longer breaks every plan. Keys regenerated outside Terraform are not picked up until you replace the matching read, for example with `terraform apply -replace='module.<module-name>.azapi_resource_action.secrets["keys"]'`. The others are `readonly_keys` and `connection_strings`.
- Changes that Azure cannot reverse now fail at apply, instead of recreating the account with its data as the AzureRM provider did: switching from continuous to periodic backups, turning off analytical storage, and removing a capability that Azure cannot remove. Turning off the analytical store of a container or graph is not sent, rather than recreating it. Changes that recreated a resource before still do, such as the kind, free tier, customer-managed key, a capability that cannot be added in place, a partition key, unique keys, a conflict resolution policy or a shard key.
- The `EnableMongo` capability, which Azure adds to MongoDB accounts, is sent with the configured capabilities.
- Changing the failover priority of a region other than the write region updates it in place. The AzureRM provider removed the region and added it back.
- Locks on the account and private endpoints are removed 30 seconds before the resources they protect, because Azure keeps enforcing a deleted lock for a few seconds.
- The private endpoints of an account are created, changed and deleted one at a time, as with the AzureRM provider, and no longer at the same time as the databases, containers, collections, graphs or throughput settings. Azure fails a private endpoint operation while another operation on the account is in progress. As with the AzureRM provider, they default to 60-minute timeouts, which include the wait for the others. Set `timeouts` higher for more than five or so private endpoints.

## Features

* Creation of accounts with NoSQL API with its databases and containers.
* Creation of accounts with Gremlin API with its databases and graphs.
* EntraID authentication instead of access keys
* Support for customer-managed keys.
* Enable private endpoint, providing secure access over a private network.
* Enable diagnostic settings.
* Creation of role assignments
* Enable locks
* Enable managed identities both system and user assigned ones.

## Limitations

* The module does not support auto rotation of Customer Managed keys (CosmosDB doesn't support it yet)
* The module does not support the Table API yet
* The module does not support the Cassandra API yet

## Examples
* [Use only defaults values](examples/default/main.tf)
* [Specifying all possible parameters at account level](examples/max-account/main.tf)
* [Creation of sql api](examples/sql/main.tf)
* [Creation of gremlin api](examples/gremlin/main.tf)
* [Creation of a serverless account](examples/serverless/main.tf)
* [Customer managed key pinning to a specific key version](examples/cmk-pin-key-version/main.tf)
* [Enable managed identities](examples/managed-identities/main.tf)
* [Enable private endpoints with auto management of dns records](examples/private-endpoints-managed-dns-records/main.tf)
* [Enable private endpoints with auto management of dns records](examples/private-endpoints-unmanaged-dns-records/main.tf)
* [Restrict public network access with access control list and service endpoints](examples/public-restricted-access/main.tf)
