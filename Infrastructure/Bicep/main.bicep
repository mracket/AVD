param location string = 'WestEurope'

resource hostpool 'Microsoft.DesktopVirtualization/hostPools@2024-08-08-preview' = {
  name: 'vdpool-avd-demo'
  location: location
  properties: {
    hostPoolType: 'Pooled'
    loadBalancerType: 'DepthFirst'
    preferredAppGroupType: 'Desktop'
  }
}

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2024-08-08-preview' = {
  name: 'avd-demo'
  location: location
  properties: {
    friendlyName: 'AVD Demo'
    applicationGroupReferences: [
      resourceId('Microsoft.DesktopVirtualization/applicationGroups', desktop_dag.name)
      resourceId('Microsoft.DesktopVirtualization/applicationGroups', remote_app_dag.name)
    ]
    description: 'AVD Demo Workspace' 
  }
}

resource desktop_dag 'Microsoft.DesktopVirtualization/applicationGroups@2024-08-08-preview' = {
  name: 'vdag-avd-demo-desktop'
  location: location
  properties: {
    friendlyName: 'AVD Demo Desktop'
    applicationGroupType: 'Desktop'
    hostPoolArmPath: resourceId('Microsoft.DesktopVirtualization/hostpools', hostpool.name)
  }
}

resource remote_app_dag 'Microsoft.DesktopVirtualization/applicationGroups@2024-08-08-preview' = {
  name: 'vdag-avd-demo-remoteapp'
  location: location
  properties: {
    friendlyName: 'AVD Demo remote app'
    applicationGroupType: 'RemoteApp'
    hostPoolArmPath: resourceId('Microsoft.DesktopVirtualization/hostpools', hostpool.name)
  }
}
