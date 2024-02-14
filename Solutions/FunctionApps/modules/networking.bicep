param location string
param vnetName string
param vnetAddressPrefix string
param subnets array
param privateDnsZoneNames array

resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  location: location
  name: vnetName //!empty(vnetName) ? vnetName : replace(nameConvVnet, 'purpose', hostingPlanName)
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: subnets
  }
}

resource snets 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' = [for subnet in subnets: {
  name: subnet.name
  parent: vnet
  properties: {
    addressPrefix: subnet.addressPrefix
  }
}]

resource dnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for zoneName in privateDnsZoneNames: {
  name: zoneName
  location: location  
}]

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for zoneName in privateDnsZoneNames: {
  name: zoneName
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
  }
}]

output subnetIds array = [for subnet in subnets: '${vnet.id}/subnets/${subnet.name}']
output privateDnsZoneIds array = [for dnsZoneName in privateDnsZoneNames: resourceId('Microsoft.Network/privateDnsZones', dnsZoneName)]
