targetScope = 'subscription'

@allowed([
  'Production'
  'Test'
])
param environment string = 'Production'
param location string = 'WestEurope'
param name string = 'level6'
param tags object = {
  Owner: 'Martin'
  Environment: environment
}
param domain_type string = 'EntraID'
param domain_guid string = 'd86cfa45-fb62-496f-8955-1ae7bcb4e0d8'
param domain_name string = 'cloudninja.nu'

param entra_group_id string = '2e822894-7b05-4c0a-9698-1c04ea8ec1cc' // ACC_AVD_Users

resource rg_hostpool 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: 'rg-${name}'
  location: location
  tags: tags
}

resource rg_shared_services 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: 'rg-${name}-shared-services'
  location: location
  tags: tags
}

module avd_hostpool 'br:acrcloudninjalevel6.azurecr.io/avd_hostpool:20251206' = {
  name: 'avd_hostpool'
  scope: rg_hostpool
  params: {
    location: location
    name: name    
    tags: tags
    vm_login_principal_id: entra_group_id
  }
}

module avd_shared_services 'br:acrcloudninjalevel6.azurecr.io/avd_shared_services:20251206' = {
  name: 'avd_shared_services'
  scope: rg_shared_services
  params: {
    location: location
    name: name    
    tags: tags
    create_storage_account: true
    create_key_vault: true
    desktop_dag: avd_hostpool.outputs.desktop_dag
    remote_app_dag: avd_hostpool.outputs.remote_app_dag
    domain_guid: domain_guid
    domain_name: domain_name
    domain_type: domain_type
  }
}

