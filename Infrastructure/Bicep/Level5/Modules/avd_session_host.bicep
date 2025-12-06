param availabilityset_name string
param location string 
param tags object

param host_pool_name string
param session_hosts_count int

@description('Virtual machine prefix name. max number of characters is 11.')
@maxLength(11)
@minLength(1)
param vm_prefix string

param subnet_name string
param virtual_network_name string
param virtual_network_resource_group_name string

param custom_image_name string = ''
param custom_image_resource_group_name string = ''
param custom_image_version string = ''
param custom_image_galery_name string = ''

param local_admin_username string
@secure()
param local_admin_password string

@allowed([
  'EntraID'
  'ActiveDirectory'
])
param domain_type string = 'EntraID'
param domain string = ''
param domain_join_username string = ''
@secure()
param domain_join_password string = ''
param ou_path string = ''
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'TrustedLaunch'
param vm_size string = 'Standard_D2s_v5'
param data_collection_rule_id string = '/subscriptions/f3b45d0c-2db9-498e-b885-9176d11d690c/resourcegroups/rg-avd-demo/providers/microsoft.insights/datacollectionrules/microsoft-avdi-westeurope-avd-demo-0-2025-10-28t06-13-46-00'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: virtual_network_name 
  scope: resourceGroup(virtual_network_resource_group_name)
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: subnet_name
  parent: vnet
}

resource customImageGallery 'Microsoft.Compute/galleries@2024-03-03' existing = if (custom_image_galery_name != '') {
  name: custom_image_galery_name
  scope: resourceGroup(custom_image_resource_group_name)
}

resource customImage 'Microsoft.Compute/galleries/images@2024-03-03' existing = if (custom_image_galery_name != '' && custom_image_name != '') {
  name: custom_image_name
  parent: customImageGallery
}

resource customSigImageVersion 'Microsoft.Compute/galleries/images/versions@2024-03-03' existing = if (custom_image_galery_name != '' && custom_image_name != '' && custom_image_version != '') {
  name: custom_image_version
  parent: customImage
}

module availabilityset 'availabilityset.bicep' = {
  name: availabilityset_name
  params: {
    location: location
    availabilitysetname: availabilityset_name
  }
}


resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = [for i in range(0, session_hosts_count): {
  name: 'nic-${vm_prefix}-${i + 1}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }      
    ]
  }  
}]

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = [for i in range(0, session_hosts_count): {
  dependsOn:[
    nic[i]
  ]
  name: '${vm_prefix}-${i + 1}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    licenseType: 'Windows_Client'
    hardwareProfile: {
      vmSize: vm_size
    }
    availabilitySet: {
      id: resourceId('Microsoft.Compute/availabilitySets', '${availabilityset.name}')
    }
    osProfile: {
      computerName: '${vm_prefix}-${i + 1}'
      adminUsername: local_admin_username
      adminPassword: local_admin_password
    }
    storageProfile: {
      imageReference: (customSigImageVersion.id != null) ? {
        id: customSigImageVersion.id
      } : {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'office-365'
        sku: 'win11-25h2-avd-m365'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic[i].id
        }
      ]
    }
    securityProfile: (securityType == 'TrustedLaunch') ? {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    } : null    
  }
}]

resource domainjoin 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = [for i in range(0, session_hosts_count): {
  name: '${vm[i].name}/domainjoin'
  location: location
  properties: (domain_type == 'EntraID') ?{
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      enable: true
      mdmId: '0000000a-0000-0000-c000-000000000000'
    }
  } : {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domain
      ouPath: ou_path
      user: domain_join_username
      restart: true
      options: 3
    }
    protectedSettings: {
      password: domain_join_password
    }
  }
  dependsOn: [
    vm[i]
  ]
}]

module hostpool 'avd_hostpool.bicep' = {
  name: 'hostpool'
  params: {
    location: location
    name: host_pool_name
    tags: tags
  }
}

resource avdagentsessionhosts 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = [for i in range(0, session_hosts_count): {
  name: '${vm[i].name}/AddSessionHost'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip'
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: hostpool.name
        registrationInfoToken: hostpool.outputs.registrationInfoToken
      }
    }
  }
  dependsOn: [
    domainjoin[i]   
  ]
}]

resource azureMonitorAgent 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = [for i in range(0, session_hosts_count): {
  name: '${vm[i].name}/AzureMonitorWindowsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {}
  }
  dependsOn: [
    vm[i]
  ]
}]

resource dcrAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11' = [for i in range(0, session_hosts_count): {
  name: 'dcr-${vm[i].name}'
  scope: vm[i]
  properties: {
    dataCollectionRuleId: data_collection_rule_id
  }
  dependsOn: [
    vm[i]
  ]
}]
