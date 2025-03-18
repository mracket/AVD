param availabilitysetname string
param location string
param platformFaultDomainCount int = 2
param platformUpdateDomainCount int = 5

resource availabilitySet 'Microsoft.Compute/availabilitySets@2024-07-01' = {
  name: availabilitysetname
  location: location
  properties: {
    platformFaultDomainCount: platformFaultDomainCount
    platformUpdateDomainCount: platformUpdateDomainCount
  }
  sku: {
    name: 'Aligned'
  }
}
