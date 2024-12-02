targetScope = 'resourceGroup'

param deploymentSuffix string
param location string
param privateDnsZoneNames array
param vnetName string
param vnetAddressPrefix string
param subnets array
param tags object

resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  location: location
  name: vnetName
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
  tags: tags[?'Microsoft.Network/virtualNetworks'] ?? {}
}

@batchSize(1)
resource snets 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' = [for subnet in subnets: {
  name: subnet.name
  parent: vnet
  properties: subnet.properties
}]

module privateDnsZones 'privateDnsZones.bicep' = if(!empty(privateDnsZoneNames)) {
  name: 'privateDns-virtualNetworkLinks-${deploymentSuffix}'
  params: {
    privateDnsZoneNames: privateDnsZoneNames
    tags: tags
    vnetId: vnet.id
  }
  dependsOn: [
    snets
  ]
}

output subnetIds array = [for subnet in subnets: '${vnet.id}/subnets/${subnet.name}']
output privateDnsZoneIds array = [for zoneName in privateDnsZoneNames: resourceId('Microsoft.Network/privateDnsZones', zoneName)]
output vnetId string = vnet.id
