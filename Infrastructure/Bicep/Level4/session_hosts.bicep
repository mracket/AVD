targetScope = 'subscription'

param availabilityset_name string = 'avail-level4'
param compute_gallery_image_name string = 'w11_multiuser_packer'
param domain string = 'cloudninja.nu'
param domain_join_username string = 'svc_domainjoin@cloudninja.nu'

@allowed([
  'Production'
  'Test'
])
param environment string = 'Production'
param host_pool_name string = 'level4'
param local_admin_username string = 'localadmin'
param key_vault_name string = 'kv-level4'
param key_vault_resource_group_name string = 'rg-level4-shared-services'
param key_vault_subscription_id string = 'f3b45d0c-2db9-498e-b885-9176d11d690c'
param location string = 'WestEurope'
param name string = 'level4'
param ou_path string = 'OU=Demo,OU=AVD,OU=Cloudninja,DC=cloudninja,DC=nu'
param session_hosts_count int = 1
param subnet_name string = 'snet-avd-cloudninja-p'
param tags object = {
  Owner: 'Martin'
  Environment: environment
}
param virtual_network_name string = 'vnet-avd-p'
param virtual_network_resource_group_name string = 'rg-avd-network-p'
param vm_prefix string = 'level4'
param vm_size string = 'Standard_D2s_v3'

resource rg_hostpool 'Microsoft.Resources/resourceGroups@2024-07-01' existing = {
  name: 'rg-${name}'
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: key_vault_name
  scope: resourceGroup(key_vault_subscription_id,key_vault_resource_group_name)
}

module avd_session_hosts 'Modules/avd_session_host.bicep' = {
  name: 'avd_session_hosts'
  scope: rg_hostpool
  params: {
    tags: tags
    subnet_name: subnet_name
    availabilityset_name: availabilityset_name
    compute_gallery_image_name: compute_gallery_image_name
    domain: domain
    domain_join_username: domain_join_username
    domain_join_password: kv.getSecret('domain-join-password')
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
  }
}
