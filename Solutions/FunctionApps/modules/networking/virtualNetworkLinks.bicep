param privateDnsZoneNames array
param vnetId string

resource privateDnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' existing = [for (name, i) in privateDnsZoneNames : {
  name: name
}]

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (name, i) in privateDnsZoneNames : {
  name: last(split(vnetId, '/'))
  parent: privateDnsZones[i]
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}]
