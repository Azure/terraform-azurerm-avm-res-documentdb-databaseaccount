# Terraform Azure Service Bus Namespace Module

This Terraform module is designed to create Azure Service bus namespaces and its related resources, including queues and topics.

> [!WARNING]
> Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. A module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>

## Features

* Creation of queues.
* Creation of topics and its subscriptions on it
* EntraID authentication instead of access keys
* Support for customer-managed keys and double encryption with infrastructure encryption.
* Enable private endpoint, providing secure access over a private network.
* Enable diagnostic settings.
* Creation of role assignments
* Enable locks
* Enable managed identities both system and user assigned ones.

## Limitations

* The module does not support configuring failover for premium tiers
* The module does not support subscription filters when creating topics

## Examples
* [Use only defaults values](examples/default/main.tf)
* [Specifying all possible parameters at namespace level](examples/max-namespace/main.tf)
* [Creation of queues](examples/queues/main.tf)
* [Creation of topics](examples/topics/main.tf)
* [Customer managed key pinning to a specific key version](examples/cmk-pin-key-version/main.tf)
* [Customer managed key using auto rotation](examples/cmk-with-auto-rotate/main.tf)
* [Enable diagnostic settings](examples/diagnostic-settings/main.tf)
* [Enable managed identities](examples/managed-identities/main.tf)
* [Enable private endpoints](examples/private-endpoints/main.tf)
* [Restrict public network access with access control list and service endpoints](examples/public-restricted-access/main.tf)
