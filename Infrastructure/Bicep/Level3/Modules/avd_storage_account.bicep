param name string
param location string
param tags object
param fileshare_name string = 'profiles'

@allowed([
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
  'Storage'
  'StorageV2'
])
param kind string = 'FileStorage'

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param sku string = 'Premium_LRS'

resource stg 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'sa${name}${uniqueString(resourceGroup().id)}'
  location: location
  kind: kind
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false    
  }  
  sku: {
    name: sku
  }
  tags: tags
}
resource file 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  name: 'default'
  parent: stg
  properties: {
    protocolSettings: {
      smb: {}
    }

  }

}

resource fileshare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  name: fileshare_name
  parent: file
  properties: {
    shareQuota: 100
  }
}
