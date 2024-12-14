param location string
param name string

@allowed([
  'Pooled'
  'Personal'
])
param hostPoolType string = 'Pooled'

@allowed([
  'BreadthFirst'
  'DepthFirst'
])
param loadBalancerType string = 'DepthFirst'

@allowed([
  'Desktop'
  'RemoteApp'
])
param preferredAppGroupType string = 'Desktop'

resource hostpool 'Microsoft.DesktopVirtualization/hostPools@2024-08-08-preview' = {
  name: 'vdpool-${name}'
  location: location
  properties: {
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    preferredAppGroupType: preferredAppGroupType
  }
}

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2024-08-08-preview' = {
  name: 'vdws-${name}'
  location: location
  properties: {
    friendlyName: '${name} workspace'
    applicationGroupReferences: [
      resourceId('Microsoft.DesktopVirtualization/applicationGroups', desktop_dag.name)
      resourceId('Microsoft.DesktopVirtualization/applicationGroups', remote_app_dag.name)
    ]
    description: '${name} Workspace' 
  }
}

resource desktop_dag 'Microsoft.DesktopVirtualization/applicationGroups@2024-08-08-preview' = {
  name: 'vdag-${name}-desktop'
  location: location
  properties: {
    friendlyName: '${name} Desktop'
    applicationGroupType: 'Desktop'
    hostPoolArmPath: resourceId('Microsoft.DesktopVirtualization/hostpools', hostpool.name)
  }
}

resource remote_app_dag 'Microsoft.DesktopVirtualization/applicationGroups@2024-08-08-preview' = {
  name: 'vdag-${name}-remoteapp'
  location: location
  properties: {
    friendlyName: '${name} remote app'
    applicationGroupType: 'RemoteApp'
    hostPoolArmPath: resourceId('Microsoft.DesktopVirtualization/hostpools', hostpool.name)
  }
}
