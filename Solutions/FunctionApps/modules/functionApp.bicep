param enableApplicationInsights bool
param enableInboundPrivateEndpoint bool
param enablePublicAccess bool
param enableStoragePrivateEndpoints bool
param functionAppInboundSubnetId string
param functionAppName string
param functionAppOutboundSubnetId string
param hostingPlanId string
param location string
param functionAppKind string
param functionAppPrivateDnsZoneId string
param logAnalyticsWorkspaceId string
param nameConvPrivEndpoints string
param runtimeVersion string
param runtimeStack string
param storageAccountResourceId string
param tags object

var functionsWorkerRuntime = runtimeVersion == '.NET Framework 4.8' || contains(runtimeVersion, 'Isolated') ? '${runtimeStack}-isolated' : runtimeStack
var firstRuntimeVersion = split(runtimeVersion, ' ')[0]
var decimalRuntimeVersion = runtimeVersion == '.NET Framework 4.8' ? '4.0' : runtimeStack == 'dotnet' && length(firstRuntimeVersion) == 1 ? '${firstRuntimeVersion}.0' : firstRuntimeVersion
var linuxRuntimeStack = contains(functionsWorkerRuntime, 'dotnet') ? toUpper(functionsWorkerRuntime) : runtimeStack == 'node' ? 'Node' : runtimeStack == 'powershell' ? 'PowerShell' : runtimeStack == 'python' ? 'Python' : runtimeStack == 'java' ? 'Java' : null

var storageConnection = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'

var commonAppSettings = [
  {
    name: 'AzureWebJobsStorage'
    value: storageConnection
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: storageConnection
  }
  {
    name: 'WEBSITE_CONTENTSHARE'
    value: toLower(functionAppName)
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: functionsWorkerRuntime
  }
]

var appInsightsAppSettings = enableApplicationInsights ? [
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: applicationInsights.properties.ConnectionString
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: applicationInsights.properties.InstrumentationKey
  }
] : []

var isolatedAppSettings = contains(functionsWorkerRuntime, 'isolated') ? [
  {
    name: 'WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED'
    value: '1'
  }
] : []

var windowsAppSettings = functionAppKind == 'functionapp' ? [
  {
    name: 'WEBSITE_NODE_DEFAULT_VERSION'
    value: '~${decimalRuntimeVersion}'
  }
] : []

var appSettings = union(commonAppSettings, appInsightsAppSettings, isolatedAppSettings, windowsAppSettings)

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: last(split(storageAccountResourceId, '/'))
  scope: resourceGroup(split(storageAccountResourceId, '/')[2], split(storageAccountResourceId, '/')[4])
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = if(enableApplicationInsights) {
  name: '${functionAppName}-insights'
  kind: 'web'
  location: location
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: !empty(logAnalyticsWorkspaceId) ? logAnalyticsWorkspaceId : null
  }
  tags: contains(tags, 'Microsoft.Insights/components') ? tags['Microsoft.Insights/components'] : {}
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  kind: functionAppKind
  location: location
  tags: contains(tags, 'Microsoft.Web/sites') ? tags['Microsoft.Web/sites'] : {}
  properties: {
    httpsOnly: true
    publicNetworkAccess: enablePublicAccess ? 'Enabled' : 'Disabled'
    serverFarmId: !empty(hostingPlanId) ? hostingPlanId : null
    siteConfig: {
      appSettings: appSettings
      linuxFxVersion: contains(functionAppKind, 'linux') ? '${linuxRuntimeStack}|${decimalRuntimeVersion}' : null
      netFrameworkVersion: !contains(functionAppKind, 'linux') && contains(runtimeStack, 'dotnet') ? 'v${decimalRuntimeVersion}' : null
    }
    virtualNetworkSubnetId: !empty(functionAppOutboundSubnetId) ? functionAppOutboundSubnetId : null
    vnetImagePullEnabled: !empty(functionAppOutboundSubnetId) ? true : false
    vnetContentShareEnabled: !empty(functionAppOutboundSubnetId) ? true : false
    vnetRouteAllEnabled: !empty(functionAppOutboundSubnetId) ? true : false
  }
}

resource functionApp_PrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = if(enableInboundPrivateEndpoint) {
  name: replace(replace(replace(nameConvPrivEndpoints, 'resourceName', functionAppName), 'service', 'sites'), '-uniqueString', uniqueString(functionAppInboundSubnetId))
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'pe-${functionAppName}-sites-connection'
        properties: {
          privateLinkServiceId: functionApp.id
          groupIds: ['sites']          
        }
      }
    ]
    subnet: {
      id: !empty(functionAppInboundSubnetId) ? functionAppInboundSubnetId : null
    }      
  }
  tags: contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {}
}

resource functionApp_PrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = if(enableInboundPrivateEndpoint) {
  name: '${functionApp_PrivateEndpoint.name}-group'
  parent: functionApp_PrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: !empty(functionAppPrivateDnsZoneId) ? '${last(split(functionAppPrivateDnsZoneId, '/'))}-config' : null
        properties: {
          privateDnsZoneId: enablePublicAccess || empty(functionAppPrivateDnsZoneId) ? null : functionAppPrivateDnsZoneId
        }
      }
    ]
  }
}

resource functionApp_diagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${functionAppName}-diagnosticSettings'
  properties: {
    logs: [
      {
        category: 'FunctionAppLogs'
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
  scope: functionApp
}
