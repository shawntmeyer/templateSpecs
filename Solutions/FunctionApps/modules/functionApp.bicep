param blobContainerName string
param enableApplicationInsights bool
param enableInboundPrivateEndpoint bool
param enablePublicAccess bool
param functionAppInboundSubnetId string
param functionAppName string
param functionAppOutboundSubnetId string
param hostingPlanId string?
param hostingPlanType string
param location string
param fileShareName string
param functionAppKind string
param functionAppPrivateDnsZoneId string
param logAnalyticsWorkspaceId string
param maximumInstanceCount int
param privateLinkScopeResourceId string
param instanceMemoryMB int
param nameConvPrivEndpoints string
param runtimeVersion string
param runtimeStack string
param storageAccountResourceId string
param tags object
param timestamp string

// existing resources

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: last(split(storageAccountResourceId, '/'))
  scope: resourceGroup(split(storageAccountResourceId, '/')[2], split(storageAccountResourceId, '/')[4])
}

// variables

var functionsWorkerRuntime = runtimeVersion == '.NET Framework 4.8' || contains(runtimeVersion, 'Isolated')
  ? '${runtimeStack}-isolated'
  : runtimeStack
var firstRuntimeVersion = split(runtimeVersion, ' ')[0]
var decimalRuntimeVersion = runtimeVersion == '.NET Framework 4.8'
  ? '4.0'
  : runtimeStack == 'dotnet' && length(firstRuntimeVersion) == 1 ? '${firstRuntimeVersion}.0' : firstRuntimeVersion
var linuxRuntimeStack = contains(functionsWorkerRuntime, 'dotnet')
  ? toUpper(functionsWorkerRuntime)
  : runtimeStack == 'node'
      ? 'Node'
      : runtimeStack == 'powershell'
          ? 'PowerShell'
          : runtimeStack == 'python' ? 'Python' : runtimeStack == 'java' ? 'Java' : null

var noFileShareAppSettings = [
    {
      name: 'AzureWebJobsStorage__blobServiceUri'
      value: 'https://${storageAccount.name}.blob.${environment().suffixes.storage}'
    }
    {
      name: 'AzureWebJobsStorage__credential'
      value: 'managedidentity'
    }
    {
      name: 'AzureWebJobsStorage__queueServiceUri'
      value: 'https://${storageAccount.name}.queue.${environment().suffixes.storage}'
    }
    {
      name: 'AzureWebJobsStorage__tableServiceUri'
      value: 'https://${storageAccount.name}.table.${environment().suffixes.storage}'
    }
    {
      name: 'FUNCTIONS_EXTENSION_VERSION'
      value: '~4'
    }
    {
      name: 'FUNCTIONS_WORKER_RUNTIME'
      value: functionsWorkerRuntime
    }
    {
      name: 'WEBSITE_LOAD_USER_PROFILE'
      value: '1'
    }
  ]

var fileShareAppSettings = [
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
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
var appInsightsAppSettings = enableApplicationInsights
  ? [
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: applicationInsights.properties.ConnectionString
      }
    ]
  : []

var isolatedAppSettings = contains(functionsWorkerRuntime, 'isolated')
  ? [
      {
        name: 'WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED'
        value: '1'
      }
    ]
  : []

var windowsAppSettings = functionAppKind == 'functionapp'
  ? [
      {
        name: 'WEBSITE_NODE_DEFAULT_VERSION'
        value: '~${decimalRuntimeVersion}'
      }
    ]
  : []

var flexAppSettings = environment().name == 'AzureCloud'
  ? [
      {
        name: 'AzureWebJobsStorage__accountName'
        value: storageAccount.name
      }
    ]
  : [
      {
        name: 'AzureWebJobsStorage__blobServiceUri'
        value: substring(
          storageAccount.properties.primaryEndpoints.blob,
          0,
          length(storageAccount.properties.primaryEndpoints.blob) - 1
        )
      }
      {
        name: 'AzureWebJobsStorage__queueServiceUri'
        value: substring(
          storageAccount.properties.primaryEndpoints.queue,
          0,
          length(storageAccount.properties.primaryEndpoints.queue) - 1
        )
      }
      {
        name: 'AzureWebJobsStorage__tableServiceUri'
        value: substring(
          storageAccount.properties.primaryEndpoints.table,
          0,
          length(storageAccount.properties.primaryEndpoints.table) - 1
        )
      }
      {
        name: 'AzureWebJobsStorage__fileServiceUri'
        value: substring(
          storageAccount.properties.primaryEndpoints.file,
          0,
          length(storageAccount.properties.primaryEndpoints.file) - 1
        )
      }
    ]

var appSettings = hostingPlanType == 'FlexConsumption'
  ? union(flexAppSettings, appInsightsAppSettings)
  : (empty(fileShareName)
      ? union(noFileShareAppSettings, appInsightsAppSettings, isolatedAppSettings, windowsAppSettings)
      : union(fileShareAppSettings, appInsightsAppSettings, isolatedAppSettings, windowsAppSettings))

// resources

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = if (enableApplicationInsights) {
  name: '${functionAppName}-insights'
  kind: 'web'
  location: location
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: !empty(logAnalyticsWorkspaceId) ? logAnalyticsWorkspaceId : null
  }
  tags: tags[?'Microsoft.Insights/components'] ?? {}
}

module updatePrivateLinkScope 'get-PrivateLinkScope.bicep' = if (enableApplicationInsights && !empty(privateLinkScopeResourceId)) {
  name: 'PrivateLlinkScope-${timestamp}'
  scope: subscription()
  params: {
    privateLinkScopeResourceId: privateLinkScopeResourceId
    scopedResourceIds: [
      applicationInsights.id
    ]
    timeStamp: timestamp
  }
}

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: functionAppName
  identity: empty(fileShareName) || hostingPlanType == 'FlexConsumption'
    ? {
        type: 'SystemAssigned'
      }
    : null
  kind: functionAppKind
  location: location
  tags: tags[?'Microsoft.Web/sites'] ?? {}
  properties: {
    httpsOnly: true
    functionAppConfig: hostingPlanType == 'FlexConsumption'
      ? {
          deployment: {
            storage: {
              type: 'blobContainer'
              value: '${storageAccount.properties.primaryEndpoints.blob}${toLower(blobContainerName)}'
              authentication: {
                type: 'SystemAssignedIdentity'
              }
            }
          }
          scaleAndConcurrency: {
            maximumInstanceCount: maximumInstanceCount
            instanceMemoryMB: instanceMemoryMB
          }
          runtime: {
            name: functionsWorkerRuntime
            version: decimalRuntimeVersion
          }
        }
      : null
    publicNetworkAccess: enablePublicAccess ? 'Enabled' : 'Disabled'
    serverFarmId: !empty(hostingPlanId) ? hostingPlanId : null
    siteConfig: hostingPlanType == 'FlexConsumption'
      ? {
          appSettings: appSettings
        }
      : {
          appSettings: appSettings
          linuxFxVersion: contains(functionAppKind, 'linux') ? '${linuxRuntimeStack}|${decimalRuntimeVersion}' : null
          netFrameworkVersion: !contains(functionAppKind, 'linux') && contains(runtimeStack, 'dotnet')
            ? 'v${decimalRuntimeVersion}'
            : null
        }
    virtualNetworkSubnetId: !empty(functionAppOutboundSubnetId) ? functionAppOutboundSubnetId : null
    vnetImagePullEnabled: hostingPlanType == 'FlexConsumption' || hostingPlanType == 'Consumption'
      ? null
      : !empty(functionAppOutboundSubnetId) ? true : false
    vnetContentShareEnabled: empty(fileShareName) ? null : !empty(functionAppOutboundSubnetId) ? true : false
    vnetRouteAllEnabled: hostingPlanType == 'FlexConsumption' || hostingPlanType == 'Consumption'
      ? null
      : !empty(functionAppOutboundSubnetId) ? true : false
  }
}

resource functionApp_PrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = if (enableInboundPrivateEndpoint) {
  name: replace(
    replace(replace(nameConvPrivEndpoints, 'RESOURCENAME', functionAppName), 'SERVICE', 'sites'),
    'VNET',
    split(functionAppInboundSubnetId, '/')[8]
  )
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
      id: functionAppInboundSubnetId
    }
  }
  tags: tags[?'Microsoft.Network/privateEndpoints'] ?? {}
}

resource functionApp_PrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = if (enableInboundPrivateEndpoint && !empty(functionAppPrivateDnsZoneId)) {
  name: '${functionApp_PrivateEndpoint.name}-group'
  parent: functionApp_PrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: !empty(functionAppPrivateDnsZoneId) ? '${last(split(functionAppPrivateDnsZoneId, '/'))}-config' : ''
        properties: {
          privateDnsZoneId: functionAppPrivateDnsZoneId
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

// Allow access from function app to storage account using a managed identity
module storageBlobDataOwnerRoleAssignment 'roleAssignment-storageAccount.bicep' = if (empty(fileShareName) || hostingPlanType == 'FlexConsumption') {
  name: 'roleAssignment-storageAccount'
  scope: resourceGroup(split(storageAccountResourceId, '/')[2], split(storageAccountResourceId, '/')[4])
  params: {
    principalId: functionApp.identity.principalId
    storageAccountResourceId: storageAccountResourceId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor role
  }
}
