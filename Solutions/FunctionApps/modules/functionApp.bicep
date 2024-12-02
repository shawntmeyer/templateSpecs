param blobContainerName string
param deploymentSuffix string
param enableApplicationInsights bool
param enableInboundPrivateEndpoint bool
param enablePublicAccess bool
param functionAppInboundSubnetId string
param functionAppName string
param functionAppOutboundSubnetId string
param hostingPlanId string?
param hostingPlanType string
param ipSecurityRestrictions array
param ipSecurityRestrictionsDefaultAction string
param scmIpSecurityRestrictions array
param scmIpSecurityRestrictionsDefaultAction string
param scmIpSecurityRestrictionsUseMain bool
param location string
param fileShareName string
param functionAppKind string
param functionAppPrivateDnsZoneId string
param logAnalyticsWorkspaceId string
param maximumInstanceCount int
param privateEndpointNameConv string
param privateEndpointNICNameConv string
param privateLinkScopeResourceId string
param instanceMemoryMB int
param runtimeVersion string
param runtimeStack string
param storageAccountResourceId string
param tags object

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

var siteConfigNetworkRestrictions = {
  ipSecurityRestrictions: empty(ipSecurityRestrictions) ? null : ipSecurityRestrictions
  ipSecurityRestrictionsDefaultAction: empty(ipSecurityRestrictions) ? null : ipSecurityRestrictionsDefaultAction
  scmIpSecurityRestrictions: empty(scmIpSecurityRestrictions) ? null : scmIpSecurityRestrictions
  scmIpSecurityRestrictionsDefaultAction: empty(scmIpSecurityRestrictions)
    ? null
    : scmIpSecurityRestrictionsDefaultAction
  scmIpSecurityRestrictionsUseMain: empty(ipSecurityRestrictions) && empty(scmIpSecurityRestrictions)
    ? null
    : scmIpSecurityRestrictionsUseMain
}
var vnetName = !empty(functionAppInboundSubnetId) ? split(functionAppInboundSubnetId, '/')[8] : ''

var privateEndpointName = length(replace(
  replace(replace(privateEndpointNameConv, 'RESOURCENAME', functionAppName), 'SERVICE', 'sites'),
  'VNET',
  vnetName
)) > 64 ? replace(
  replace(replace(privateEndpointNameConv, 'RESOURCENAME', replace(functionAppName, '-', '')), 'SERVICE', 'sites'),
  'VNET',
  replace(vnetName, '-', '')
) : replace(
  replace(replace(privateEndpointNameConv, 'RESOURCENAME', functionAppName), 'SERVICE', 'sites'),
  'VNET',
  vnetName
)

var privateEndpointNICName = length(replace(
  replace(replace(privateEndpointNICNameConv, 'SERVICE', 'sites'), 'RESOURCENAME', functionAppName),
  'VNET',
  vnetName
)) > 80 ? replace(
  replace(replace(privateEndpointNICNameConv, 'SERVICE', 'sites'), 'RESOURCENAME', replace(functionAppName, '-', '')),
  'VNET',
  replace(vnetName, '-', '')
) : replace(
  replace(replace(privateEndpointNICNameConv, 'SERVICE', 'sites'), 'RESOURCENAME', functionAppName),
  'VNET',
  vnetName
)

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
  name: 'PrivateLinkScope-${deploymentSuffix}'
  scope: subscription()
  params: {
    privateLinkScopeResourceId: privateLinkScopeResourceId
    scopedResourceIds: [
      applicationInsights.id
    ]
    deploymentSuffix: deploymentSuffix
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
      ? union(
          {
            appSettings: appSettings
          },
          siteConfigNetworkRestrictions
        )
      : union(
          {
            appSettings: appSettings
            linuxFxVersion: contains(functionAppKind, 'linux') ? '${linuxRuntimeStack}|${decimalRuntimeVersion}' : null
            netFrameworkVersion: !contains(functionAppKind, 'linux') && contains(runtimeStack, 'dotnet')
              ? 'v${decimalRuntimeVersion}'
              : null
          },
          siteConfigNetworkRestrictions
        )
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

resource functionApp_PrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (enableInboundPrivateEndpoint) {
  name: privateEndpointName
  location: location
  properties: {
    customNetworkInterfaceName: privateEndpointNICName
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
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
  name: privateEndpointName
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
