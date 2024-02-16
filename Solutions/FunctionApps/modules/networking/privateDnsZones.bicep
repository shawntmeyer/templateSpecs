param privateDnsZoneNames array
param vnetId string
param tags object

resource privateDnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for (name, i) in privateDnsZoneNames: {
  name: name
  location: 'global'
  tags: contains(tags, 'Microsoft.Network/privateDnsZones') ? tags['Microsoft.Network/privateDnsZones'] : {}
}]

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (name, i) in privateDnsZoneNames : {
  name: '${last(split(vnetId, '/'))}-link'
  parent: privateDnsZones[i]
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
  dependsOn: [privateDnsZones[i]]
}]
