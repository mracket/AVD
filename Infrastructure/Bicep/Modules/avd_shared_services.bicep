// Shared parameters
param location string
param name string
param tags object

// Storage account params
param create_storage_account bool = false
param create_key_vault bool = false
param desktop_dag string
param fileshare_name string = 'profiles'
@allowed([
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
  'Storage'
  'StorageV2'
])
param kind string = 'FileStorage'
param remote_app_dag string
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param sku string = 'Premium_LRS'
param domain_type string = ''
param domain_guid string = ''
param domain_name string = ''

param principalId string = 'bf92430d-f01e-46ea-8fef-092a87a81e97'

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2024-08-08-preview' = {
  name: 'vdws-${name}'
  location: location
  properties: {
    applicationGroupReferences: [
      desktop_dag
      remote_app_dag
    ]
    description: '${name} Workspace'
    friendlyName: '${name} workspace'
  }
  tags: tags
}

resource stg 'Microsoft.Storage/storageAccounts@2025-06-01' =  if (create_storage_account) {
  name: 'sa${name}${uniqueString(resourceGroup().id)}'
  location: location
  kind: kind
  properties: {
    allowBlobPublicAccess: false  
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    azureFilesIdentityBasedAuthentication: (domain_type == 'EntraID') ?{
      activeDirectoryProperties: {
        domainGuid: domain_guid
        domainName: domain_name
      }
      directoryServiceOptions: 'AADKERB'
      defaultSharePermission: 'StorageFileDataSmbShareContributor'
    }: null
  }  
  sku: {
    name: sku
  }
  tags: tags
}
resource file 'Microsoft.Storage/storageAccounts/fileServices@2025-06-01' =  if (create_storage_account) {
  name: 'default'
  parent: stg
  properties: {
    protocolSettings: {
      smb: {}
    }
  }
}

resource fileshare 'Microsoft.Storage/storageAccounts/fileServices/shares@2025-06-01' = if (create_storage_account) {
  name: fileshare_name
  parent: file
  properties: {
    shareQuota: 100
  }
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = if (create_key_vault) {
  name: 'kv-${name}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
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


