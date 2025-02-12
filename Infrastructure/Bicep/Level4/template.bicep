
param compute_gallery_name string 
param image_name string 
param location string
param managed_identity_name string 
param managed_identity_resource_group_name string  

resource compute_gallery_lookup 'Microsoft.Compute/galleries@2024-03-03' existing = {
  name: compute_gallery_name
}

resource compute_gallery_image_definition 'Microsoft.Compute/galleries/images@2024-03-03' = {
  parent: compute_gallery_lookup
  name: image_name
  location: location
  properties: {
    description: 'Used for ${image_name}'
    identifier: {
      sku: 'win11-24h2-${image_name}'
      offer: 'office-365'
      publisher: 'microsoftwindowsdesktop'
    }
    osState: 'Generalized'
    osType: 'Windows'
    endOfLifeDate: '2099-01-01'
    hyperVGeneration: 'V2'
  }
}

resource managed_identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' existing = {
  name: managed_identity_name
  scope: resourceGroup(managed_identity_resource_group_name)
}

resource image_template 'Microsoft.VirtualMachineImages/imageTemplates@2024-02-01' = {
  name: image_name
  location: location
  tags: {
    AVD_IMAGE_TEMPLATE: 'AVD_IMAGE_TEMPLATE'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managed_identity.id}': {}
    }
  }
  properties: {
    buildTimeoutInMinutes: 0
    customize: [
      {
        destination: 'C:\\AVDImage\\configureSessionTimeouts.ps1'
        name: 'avdBuiltInScript_configureSessionTimeouts'
        sha256Checksum: 'abb1d5ba922013864c94d7a92a5d0aae7ae50805563af2b3777ba9b74ca6ccc4'
        sourceUri: 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2024-03-27/ConfigureSessionTimeoutsV2.ps1'
        type: 'File'
      }
      {
        inline: [
          'C:\\AVDImage\\configureSessionTimeouts.ps1 -MaxDisconnectionTime "15" -MaxIdleTime "15" -MaxConnectionTime "60" -RemoteAppLogoffTimeLimit "0"'
        ]
        name: 'avdBuiltInScript_configureSessionTimeouts-parameter'
        runAsSystem: true
        runElevated: true
        type: 'PowerShell'
      }
      {
        destination: 'C:\\AVDImage\\multiMediaRedirection.ps1'
        name: 'avdBuiltInScript_multiMediaRedirection'
        sha256Checksum: 'f577c9079aaa7da399121879213825a3f263f7b067951a234509e72f8b59a7fd'
        sourceUri: 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2024-03-27/MultiMediaRedirection.ps1'
        type: 'File'
      }
      {
        inline: [
          'C:\\AVDImage\\multiMediaRedirection.ps1 -VCRedistributableLink "https://aka.ms/vs/17/release/vc_redist.x64.exe" -EnableEdge "true" -EnableChrome "true"'
        ]
        name: 'avdBuiltInScript_multiMediaRedirection-parameter'
        runAsSystem: true
        runElevated: true
        type: 'PowerShell'
      }
      {
        name: 'avdBuiltInScript_disableStorageSense'
        runAsSystem: true
        runElevated: true
        scriptUri: 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2024-03-27/DisableStorageSense.ps1'
        sha256Checksum: 'f486df3c245f93bcf53b9c68b17741a732e6641703e2eea4234a27e30e39e983'
        type: 'PowerShell'
      }
      {
        name: 'avdBuiltInScript_windowsUpdate'
        type: 'WindowsUpdate'
        updateLimit: 0
      }
      {
        name: 'avdBuiltInScript_windowsUpdate-windowsRestart'
        type: 'WindowsRestart'
      }
      {
        name: 'avdBuiltInScript_adminSysPrep'
        runAsSystem: true
        runElevated: true
        scriptUri: 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2024-03-27/AdminSysPrep.ps1'
        sha256Checksum: '1dcaba4823f9963c9e51c5ce0adce5f546f65ef6034c364ef7325a0451bd9de9'
        type: 'PowerShell'
      }
    ]
    distribute: [
      {
        artifactTags: {}
        excludeFromLatest: false
        galleryImageId: compute_gallery_image_definition.id
        replicationRegions: [
          'westeurope'
        ]
        runOutputName: 'output-${image_name}'
        type: 'SharedImage'
      }
    ]
    source: {
      offer: 'office-365'
      publisher: 'microsoftwindowsdesktop'
      sku: 'win11-24h2-avd-m365'
      type: 'PlatformImage'
      version: 'latest'
    }
    vmProfile: {
      osDiskSizeGB: 127
      vmSize: 'Standard_D4s_v5'
    }
  }
}
