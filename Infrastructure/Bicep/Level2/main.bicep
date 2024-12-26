targetScope = 'subscription'

param location string = 'WestEurope'
param name string = 'level2'

@allowed([
  'Production'
  'Test'
])
param environment string = 'Production'

param tags object = {
  Owner: 'Martin'
  Environment: environment
}

resource rg 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: 'rg-${name}'
  location: location
  tags: tags
}

module avd 'Modules/avd.bicep' = {
  name: 'avd'
  scope: rg
  params: {
    location: location
    name: name    
    tags: tags
  }
}
