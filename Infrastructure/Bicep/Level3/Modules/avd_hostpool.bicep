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
  param location string
  param name string
  @allowed([
    'Desktop'
    'RemoteApp'
  ])
  param preferredAppGroupType string = 'Desktop'
  param tags object

  resource hostpool 'Microsoft.DesktopVirtualization/hostPools@2024-08-08-preview' = {
    name: 'vdpool-${name}'
    location: location
    properties: {
      hostPoolType: hostPoolType
      loadBalancerType: loadBalancerType
      preferredAppGroupType: preferredAppGroupType
    }
    tags: tags
  }

  resource desktop_dag 'Microsoft.DesktopVirtualization/applicationGroups@2024-08-08-preview' = {
    name: 'vdag-${name}-desktop'
    location: location
    properties: {
      applicationGroupType: 'Desktop'
      friendlyName: '${name} Desktop'    
      hostPoolArmPath: resourceId('Microsoft.DesktopVirtualization/hostpools', hostpool.name)
    }
    tags: tags
  }

  resource remote_app_dag 'Microsoft.DesktopVirtualization/applicationGroups@2024-08-08-preview' = {
    name: 'vdag-${name}-remoteapp'
    location: location
    properties: {
      applicationGroupType: 'RemoteApp'
      friendlyName: '${name} remote app'    
      hostPoolArmPath: resourceId('Microsoft.DesktopVirtualization/hostpools', hostpool.name)
    }
    tags: tags
  }

  output desktop_dag string = resourceId('Microsoft.DesktopVirtualization/applicationGroups', desktop_dag.name)
  output remote_app_dag string = resourceId('Microsoft.DesktopVirtualization/applicationGroups',remote_app_dag.name)
