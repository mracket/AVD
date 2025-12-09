@minLength(3)
param name string = 'level6'
param project string = 'AVD'

resource cr 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: 'acr${name}'
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: false
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        status: 'disabled'
      }
    }
  }
  tags: {
    environment: name
    project: project
  }
}

