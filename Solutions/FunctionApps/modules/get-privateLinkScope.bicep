targetScope = 'subscription'

param privateLinkScopeResourceId string
param scopedResourceIds array
param location string

module addScopedResources 'addScopedResources-PrivateLinkScope.bicep' = {
  scope: resourceGroup(split(privateLinkScopeResourceId, '/')[2], split(privateLinkScopeResourceId, '/')[4])
  name: 'addScopedResources-${uniqueString(deployment().name, location)}'
  params: {
    privateLinkScopeResourceId: privateLinkScopeResourceId
    scopedResourceIds: scopedResourceIds
  }
}
