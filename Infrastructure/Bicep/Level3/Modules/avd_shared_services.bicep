// Shared parameters
param location string
param name string
param tags object

// Storage account params
param create_storage_account bool = false
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

module storage_account 'avd_storage_account.bicep' = if (create_storage_account)  {
  name: 'storage_account'
  params: {
    fileshare_name: fileshare_name
    kind: kind
    location: location
    name: name
    tags: tags    
    sku: sku
  }
}
