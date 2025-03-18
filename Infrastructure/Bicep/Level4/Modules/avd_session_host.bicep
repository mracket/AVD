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

param local_admin_username string
@secure()
param local_admin_password string

param domain string
param domain_join_username string
@secure()
param domain_join_password string
param ou_path string
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'TrustedLaunch'
param vm_size string = 'Standard_D2s_v5'

param compute_gallery_name string = 'gal_avd'
param compute_gallery_image_name string
param compute_gallery_resource_group string = 'rg-avd-sharedservices-p'
param compute_gallery_subscription_id string = 'f3b45d0c-2db9-498e-b885-9176d11d690c'
param use_compute_gallery bool = true

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: virtual_network_name 
  scope: resourceGroup(virtual_network_resource_group_name)
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: subnet_name
  parent: vnet
}

module availabilityset 'availabilityset.bicep' = {
  name: availabilityset_name
  params: {
    location: location
    availabilitysetname: availabilityset_name
  }
}

resource gallery 'Microsoft.Compute/galleries@2024-03-03' existing = if(use_compute_gallery) {
  name: compute_gallery_name
  scope: resourceGroup(compute_gallery_subscription_id, compute_gallery_resource_group)
}

resource galleryimage 'Microsoft.Compute/galleries/images@2024-03-03' existing = if(use_compute_gallery){
  name: compute_gallery_image_name
  parent: gallery
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
      imageReference: (use_compute_gallery) ? {
        id: galleryimage.id        
      } : {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'office-365'
        sku: '24h2-avd'
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

resource domainjoinsessionhosts 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = [for i in range(0, session_hosts_count): {
  name: '${vm[i].name}/JoinDomain'
  location: location
  properties: {
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
    domainjoinsessionhosts[i]   
  ]
}]
