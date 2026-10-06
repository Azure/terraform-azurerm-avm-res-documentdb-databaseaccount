# Managed identity example

This example deploys the module with system and user assigned managed identities.

It also grants the user assigned identity a role on the account. The role assignment sets `principal_type = "ServicePrincipal"`, which Azure requires when the deploying identity is constrained by ABAC conditions that filter on principal type.
