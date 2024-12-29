targetScope = 'subscription'

param location string = 'WestEurope'
param name string = 'level3'

@allowed([
  'Production'
  'Test'
])
param environment string = 'Production'

param tags object = {
  Owner: 'Martin'
  Environment: environment
}

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

module avd_hostpool 'Modules/avd_hostpool.bicep' = {
  name: 'avd_hostpool'
  scope: rg_hostpool
  params: {
    location: location
    name: name    
    tags: tags
  }
}

module avd_shared_services 'Modules/avd_shared_services.bicep' = {
  name: 'avd_shared_services'
  scope: rg_shared_services
  params: {
    location: location
    name: name    
    tags: tags
    create_storage_account: true
    desktop_dag: avd_hostpool.outputs.desktop_dag
    remote_app_dag: avd_hostpool.outputs.remote_app_dag
  }
}
