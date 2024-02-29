param location string
param logAnalyticsWorkspaceId string
param name string
param sku object
param tags object
param zoneRedundant bool


resource hostingPlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: name
  location: location
  sku: sku
  tags: contains(tags, 'Microsoft.Web/serverfarms') ? tags['Microsoft.Web/serverfarms'] : {}
  properties: {
    maximumElasticWorkerCount: 20
    zoneRedundant: zoneRedundant
    numberOfWorkers: zoneRedundant? 3 : null
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
