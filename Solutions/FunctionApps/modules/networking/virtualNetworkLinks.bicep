param privateDnsZoneNames array
param vnetId string

resource privateDnsZones 'Microsoft.Network/privateDnsZones@2018-09-01' existing = [for (name, i) in privateDnsZoneNames : {
  name: name
}]

resource virtualNetworkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = [for (name, i) in privateDnsZoneNames : {
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
