targetScope = 'subscription'

param deploymentSuffix string
param privateLinkScopeResourceId string
param scopedResourceIds array

module addScopedResources 'addScopedResources-PrivateLinkScope.bicep' = {
  scope: resourceGroup(split(privateLinkScopeResourceId, '/')[2], split(privateLinkScopeResourceId, '/')[4])
  name: 'addScopedResources-${deploymentSuffix}'
  params: {
    privateLinkScopeResourceId: privateLinkScopeResourceId
    scopedResourceIds: scopedResourceIds
  }
}
