param location string
param name string
param tags object
param create_storage_account bool = false
param desktop_dag string
param remote_app_dag string

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2024-08-08-preview' = {
  name: 'vdws-${name}'
  location: location
  properties: {
    friendlyName: '${name} workspace'
    applicationGroupReferences: [
      desktop_dag
      remote_app_dag
    ]
    description: '${name} Workspace' 
  }
  tags: tags
}

module storage_account 'avd_storage_account.bicep' = if (create_storage_account)  {
  name: 'storage_account'
  params: {
    name: name
    location: location
    tags: tags
  }
}
