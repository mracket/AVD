targetScope = 'subscription'

param availabilityset_name string = 'avail-level6'
param domain string = 'cloudninja.nu'
param domain_join_username string = 'svc_domainjoin@cloudninja.nu'
param domain_type string = 'EntraID'

@allowed([
  'Production'
  'Test'
])
param environment string = 'Production'
param host_pool_name string = 'level6'
param local_admin_username string = 'localadmin'
param key_vault_name string = 'kv-level6'
param key_vault_resource_group_name string = 'rg-level6-shared-services'
param key_vault_subscription_id string = 'f3b45d0c-2db9-498e-b885-9176d11d690c'
param location string = 'WestEurope'
param name string = 'level6'
param ou_path string = ''
param session_hosts_count int = 1
param subnet_name string = 'snet-avd-cloudninja-p'
param tags object = {
  Owner: 'Martin'
  Environment: environment
}
param virtual_network_name string = 'vnet-avd-p'
param virtual_network_resource_group_name string = 'rg-avd-network-p'
param vm_prefix string = 'level6'
param vm_size string = 'Standard_D2s_v3'

resource rg_hostpool 'Microsoft.Resources/resourceGroups@2024-07-01' existing = {
  name: 'rg-${name}'
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: key_vault_name
  scope: resourceGroup(key_vault_subscription_id,key_vault_resource_group_name)
}

module avd_session_hosts 'br:acrcloudninjalevel6.azurecr.io/avd_session_host:2025-12-06' = {
  name: 'avd_session_hosts'
  scope: rg_hostpool
  params: {
    tags: tags
    subnet_name: subnet_name
    availabilityset_name: availabilityset_name
    custom_image_galery_name: 'gal_avd'
    custom_image_name: 'w11_multiuser_packer'
    custom_image_resource_group_name: 'rg-avd-sharedservices-p'
    domain: domain
    domain_join_username: (domain_type == 'EntraID') ? '' : domain_join_username
    domain_join_password: (domain_type == 'EntraID') ? '' : kv.getSecret('domain-join-password')
    host_pool_name: host_pool_name
    local_admin_password: kv.getSecret('local-admin-password')
    local_admin_username: local_admin_username
    location: location
    ou_path: ou_path
    session_hosts_count: session_hosts_count
    virtual_network_name: virtual_network_name
    virtual_network_resource_group_name: virtual_network_resource_group_name
    vm_prefix: vm_prefix
    vm_size: vm_size
    domain_type: domain_type
  }
}
