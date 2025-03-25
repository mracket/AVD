param location string 
param name string
param principalId string = 'bf92430d-f01e-46ea-8fef-092a87a81e97'
param tags object

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${name}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
  }
  tags: tags
}

resource key_vault_administrator 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'bf92430d-f01e-46ea-8fef-092a87a81e97'
}

resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, principalId, key_vault_administrator.id)
  properties: {
    principalId: principalId
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483'    
  }
  scope: kv
}

