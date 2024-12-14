targetScope = 'subscription'

param location string = 'WestEurope'
param name string = 'level2'

resource rg 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: 'rg-${name}'
  location: location
}

module avd 'Modules/avd.bicep' = {
  name: 'avd'
  scope: rg
  params: {
    location: location
    name: name    
  }
}
