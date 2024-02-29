param location string
param logAnalyticsWorkspaceId string
param name string
param planPricing string
param tags object
param zoneRedundant bool

var sku = {
  name: split(planPricing, '_')[1]
  tier: split(planPricing, '_')[0]
  capacity: zoneRedundant ? 3 : 1
}

resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: name
  location: location
  kind: 'elastic'
  sku: sku
  tags: contains(tags, 'Microsoft.Web/serverfarms') ? tags['Microsoft.Web/serverfarms'] : {}
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: true
    isSpot: false
    reserved: false    
    maximumElasticWorkerCount: 20
    zoneRedundant: zoneRedundant
  }
}

resource hostingPlan_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(!empty(logAnalyticsWorkspaceId)) {
  name: '${name}-diagnosticSettings'
  properties: {
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
  scope: hostingPlan
}

output hostingPlanId string = hostingPlan.id
