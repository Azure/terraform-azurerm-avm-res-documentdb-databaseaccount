locals {
  private_dns_zone_group_imports = {
    for k, v in local.private_dns_zone_groups : k => "${local.private_endpoint_parent_ids[k]}/providers/Microsoft.Network/privateEndpoints/${local.private_endpoint_names[k]}/privateDnsZoneGroups/${v.name}?api-version=${split("@", var.resource_types.network_private_endpoints_private_dns_zone_groups)[1]}"
  }
  # The zone groups of managed private endpoints, which earlier versions managed as part of the private endpoint.
  # Built from the configuration, so they are known when planning the upgrade.
  private_dns_zone_groups = {
    for k, v in var.private_endpoints : k => {
      name                          = v.private_dns_zone_group_name
      private_dns_zone_resource_ids = v.private_dns_zone_resource_ids
    } if var.private_endpoints_manage_dns_zone_group && length(v.private_dns_zone_resource_ids) > 0
  }
  private_endpoint_application_security_group_associations = {
    for assoc in flatten([
      for pe_k, pe_v in var.private_endpoints : [
        for asg_k, asg_v in pe_v.application_security_group_associations : {
          asg_key         = asg_k
          pe_key          = pe_k
          asg_resource_id = asg_v
        }
      ]
    ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc
  }
  private_endpoint_ids = merge(
    { for k, v in azapi_resource.private_endpoints : k => v.id },
    { for k, v in azapi_resource.private_endpoints_unmanaged : k => v.id },
  )
  private_endpoint_names = { for k, v in var.private_endpoints : k => v.name != null ? v.name : "pep-${var.name}" }
  # The resource group of each private endpoint. As before, a resource group given by ID is used by name, in the
  # subscription of the account.
  private_endpoint_parent_ids = {
    for k, v in var.private_endpoints : k => v.resource_group_name == null ? var.parent_id : "/subscriptions/${local.subscription_id}/resourceGroups/${try(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", v.resource_group_name).resource_group_name, v.resource_group_name)}"
  }
  private_endpoint_properties = {
    for k, v in var.private_endpoints : k => {
      applicationSecurityGroups  = [for id in values(v.application_security_group_associations) : { id = id }]
      customNetworkInterfaceName = v.network_interface_name
      ipConfigurations = [
        for ip_configuration in values(v.ip_configurations) : {
          name = ip_configuration.name
          properties = {
            groupId          = v.subresource_name
            memberName       = coalesce(ip_configuration.member_name, v.subresource_name)
            privateIPAddress = ip_configuration.private_ip_address
          }
        }
      ]
      privateLinkServiceConnections = [
        {
          name = v.private_service_connection_name != null ? v.private_service_connection_name : "pse-${k}"
          properties = {
            groupIds             = [v.subresource_name]
            privateLinkServiceId = azapi_resource.this.id
          }
        }
      ]
      subnet = {
        id = v.subnet_resource_id
      }
    }
  }
  # The AzureRM provider replaced a private endpoint when one of these settings changed. While the prior value is
  # null, as it is straight after upgrading from AzureRM, nothing is replaced.
  private_endpoint_replace_triggers = {
    for k, v in var.private_endpoints : k => {
      ip_configurations               = local.private_endpoint_properties[k].ipConfigurations
      network_interface_name          = v.network_interface_name
      private_service_connection_name = local.private_endpoint_properties[k].privateLinkServiceConnections[0].name
      subnet_resource_id              = lower(v.subnet_resource_id)
      subresource_name                = v.subresource_name
    }
  }
  # As before, a private endpoint without tags of its own takes the tags of the account.
  private_endpoint_tags = { for k, v in var.private_endpoints : k => v.tags != null ? v.tags : var.tags }
}
