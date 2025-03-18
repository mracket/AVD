param compute_gallery_name string = 'gal_cloudninja_production'
param image_name string = 'AVD-Image-13022025-8'
param location string = 'WestEurope'
param managed_identity_name string = 'mi-github-cloudninja-avd'
param managed_identity_resource_group_name string = 'rg-avd-tfstate-p'

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
    features: [
      {
        name: 'SecurityType'
        value: 'TrustedLaunchSupported'
      }
    ]
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
    buildTimeoutInMinutes: 240
    customize: [
      {
        name: 'google chrome'
        runAsSystem: true
        runElevated: true
        scriptUri: 'https://cnjimagebuilder.blob.core.windows.net/scripts/google_chrome.ps1'
        type: 'PowerShell'
      }
      {
        name: 'powershell'
        runAsSystem: true
        runElevated: true
        scriptUri: 'https://cnjimagebuilder.blob.core.windows.net/scripts/Microsoft_PowerShell_Core.ps1'
        type: 'PowerShell'
      }
      {
        name: 'vs code'
        runAsSystem: true
        runElevated: true
        scriptUri: 'https://cnjimagebuilder.blob.core.windows.net/scripts/Microsoft_visual_studio_code.ps1'
        type: 'PowerShell'
      }
      {
        destination: 'C:\\AVDImage\\windowsOptimization.ps1'
        name: 'avdBuiltInScript_windowsOptimization'
        sha256Checksum: '3a84266be0a3fcba89f2adf284f3cc6cc2ac41242921010139d6e9514ead126f'
        sourceUri: 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2024-03-27/WindowsOptimization.ps1'
        type: 'File'
      }
      {
        inline: [
          'C:\\AVDImage\\windowsOptimization.ps1 -Optimizations "ScheduledTasks","Services","Edge","LGPO"'
        ]
        name: 'avdBuiltInScript_windowsOptimization-parameter'
        runAsSystem: true
        runElevated: true
        type: 'PowerShell'
      }
      {
        name: 'avdBuiltInScript_windowsOptimization-windowsUpdate'
        type: 'WindowsUpdate'
        updateLimit: 0
      }
      {
        name: 'avdBuiltInScript_windowsOptimization-windowsRestart'
        type: 'WindowsRestart'
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
        runOutputName: 'output-ad-image'
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
      vmSize: 'Standard_D8s_v3'      
    }
    
  }
}
