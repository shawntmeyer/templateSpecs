param enableApplicationInsights bool
param enableInboundPrivateEndpoint bool
param enableStoragePrivateEndpoints bool
param enablePublicAccess bool
param logicAppName string
param logicAppInboundSubnetId string
param logicAppOutboundSubnetId string
param logicAppPrivateDnsZoneId string
param location string
param logAnalyticsWorkspaceId string
param nameConvPrivEndpoints string
param hostingPlanId string
param storageAccountResourceId string
param tags object

var storageConnection = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'

var commonAppSettings = [
  {
    name: 'APP_KIND'
    value: 'workflowapp'
  }
  {
    name: 'AzureWebJobsStorage'
    value: storageConnection
  }
  {
    name: 'AzureFunctionsJobHost__extensionBundle__id'
    value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
  }  
  {
    name: ' AzureFunctionsJobHost__extensionBundle__version'
    value: '[1.*, 2.0.0)'
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: 'node'
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: storageConnection
  }
  {
    name: 'WEBSITE_CONTENTSHARE'
    value: toLower(logicAppName)
  }
  {
    name: 'WEBSITE_NODE_DEFAULT_VERSION'
    value: '~18'
  }
]

var appApplicationInsights = enableApplicationInsights ? [
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: applicationInsights.properties.ConnectionString
  }
] : []

var appSettings = union(commonAppSettings, appApplicationInsights)

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: last(split(storageAccountResourceId, '/'))
  scope: resourceGroup(split(storageAccountResourceId, '/')[2], split(storageAccountResourceId, '/')[4])
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02-preview' = if(enableApplicationInsights) {
  name: '${logicAppName}-insights'
  kind: 'web'
  location: location
  properties: {
    Application_Type: 'web'
    Request_Source: 'IbizaWebAppExtensionCreate'
    Flow_Type: 'RedField'
    WorkspaceResourceId: !empty(logAnalyticsWorkspaceId) ? logAnalyticsWorkspaceId : null
  }
  tags: contains(tags, 'Microsoft.Insights/components') ? tags['Microsoft.Insights/components'] : {}
}

resource logicApp 'Microsoft.Web/sites@2023-01-01' = {
  name: logicAppName
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  location: location
  tags: contains(tags, 'Microsoft.Web/sites') ? tags['Microsoft.Web/sites'] : {}
  properties: {
    httpsOnly: true
    publicNetworkAccess: enablePublicAccess ? 'Enabled' : 'Disabled'
    serverFarmId: !empty(hostingPlanId) ? hostingPlanId : null
    siteConfig: {
      ftpsState: 'FtpsOnly'
      netFrameworkVersion: 'v6.0'
      use32BitWorkerProcess: false
      appSettings: appSettings
    }
    virtualNetworkSubnetId: !empty(logicAppOutboundSubnetId) ? logicAppOutboundSubnetId : null
    vnetImagePullEnabled: enableStoragePrivateEndpoints ? true : false
    vnetContentShareEnabled: enableStoragePrivateEndpoints ? true : false
    vnetRouteAllEnabled: enableStoragePrivateEndpoints ? true : false
  }
}

resource logicApp_PrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = if(enableInboundPrivateEndpoint) {
  name: replace(replace(replace(nameConvPrivEndpoints, 'resourceName', logicAppName), 'service', 'sites'), '-uniqueString', uniqueString(logicAppInboundSubnetId))
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'pe-${logicAppName}-sites-connection'
        properties: {
          privateLinkServiceId: logicApp.id
          groupIds: ['sites']          
        }
      }
    ]
    subnet: {
      id: !empty(logicAppInboundSubnetId) ? logicAppInboundSubnetId : null
    }      
  }
  tags: contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {}
}

resource logicApp_PrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = if(enableInboundPrivateEndpoint) {
  name: '${logicApp_PrivateEndpoint.name}-group'
  parent: logicApp_PrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: !empty(logicAppPrivateDnsZoneId) ? '${last(split(logicAppPrivateDnsZoneId, '/'))}-config' : null
        properties: {
          privateDnsZoneId: enablePublicAccess || empty(logicAppPrivateDnsZoneId) ? null : logicAppPrivateDnsZoneId
        }
      }
    ]
  }
}

resource logicApp_diagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${logicAppName}-diagnosticSettings'
  properties: {
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
      }
      {
        category: 'WorkflowRuntime'
        enabled: true
      
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
  scope: logicApp
}
