param location string
param privateDnsZoneNames array
param vnetName string
param vnetAddressPrefix string
param subnets array
param tags object
param timestamp string

resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  location: location
  name: vnetName //!empty(vnetName) ? vnetName : replace(nameConvVnet, 'purpose', hostingPlanName)
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
  tags: contains(tags, 'Microsoft.Network/virtualNetworks') ? tags['Microsoft.Network/virtualNetworks'] : {}
}

resource snets 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' = [for subnet in subnets: {
  name: subnet.name
  parent: vnet
  properties: subnet.properties
}]

resource privateDnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for zoneName in privateDnsZoneNames: {
  name: zoneName
  location: 'global'
  tags: contains(tags, 'Microsoft.Network/privateDnsZones') ? tags['Microsoft.Network/privateDnsZones'] : {}
}]

// had to call module for VNetLinks to successfully create the links.
module virtualNetworkLinks './networking/virtualNetworkLinks.bicep' = {
  name: 'virtualNetworkLinks-${timestamp}'
  params: {
    vnetId: vnet.id
    privateDnsZoneNames: privateDnsZoneNames
  }
  dependsOn: [
    privateDnsZones
  ]
}

output subnetIds array = [for subnet in subnets: '${vnet.id}/subnets/${subnet.name}']
output privateDnsZoneIds array = [for zoneName in privateDnsZoneNames: resourceId('Microsoft.Network/privateDnsZones', zoneName)]
output vnetId string = vnet.id
