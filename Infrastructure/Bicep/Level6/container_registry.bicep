

resource cr 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: 'acrcloudninjalevel6'
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
    environment: 'Level6'
    project: 'AVD'
  }
}

