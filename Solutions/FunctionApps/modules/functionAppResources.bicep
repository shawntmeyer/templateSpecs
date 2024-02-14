param functionAppName string
param location string
param tags object
param enableApplicationInsights bool
param nameConvPrivEndpoints string
param logAnalyticsWorkspaceId string
param functionAppKind string
param enableInboundPrivateEndpoint bool
param enablePublicAccess bool
param enableVnetIntegration bool
param functionAppInboundSubnetId string
param functionAppOutboundSubnetId string
param runtimeVersion string
param runtimeStack string
param hostingPlanId string
param storageAccountName string
param storageBlobDnsZoneId string
param storageFileDnsZoneId string
param storageQueueDnsZoneId string
param storageTableDnsZoneId string
param functionAppPrivateDnsZoneId string
param storageAccountPrivateEndpointSubnetId string

var functionsWorkerRuntime = runtimeVersion == '.NET Framework 4.8' || contains(runtimeVersion, 'Isolated') ? '${runtimeStack}-isolated' : runtimeStack
var firstRuntimeVersion = split(runtimeVersion, ' ')[0]
var decimalRuntimeVersion = runtimeVersion == '.NET Framework 4.8' ? '4.0' : runtimeStack == 'dotnet' && length(firstRuntimeVersion) == 1 ? '${firstRuntimeVersion}.0' : firstRuntimeVersion
var linuxRuntimeStack = contains(functionsWorkerRuntime, 'dotnet') ? toUpper(functionsWorkerRuntime) : runtimeStack == 'node' ? 'Node' : runtimeStack == 'powershell' ? 'PowerShell' : runtimeStack == 'python' ? 'Python' : runtimeStack == 'java' ? 'Java' : null

var commonAppSettings = {
  APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString
  APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsights.properties.InstrumentationKey
  AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  WEBSITE_CONTENTSHARE: toLower(functionAppName)
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: functionsWorkerRuntime
}

var isolatedAppSettings = {
  WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED: '1'
}

var windowsAppSettings = {
  WEBSITE_NODE_DEFAULT_VERSION: '~${decimalRuntimeVersion}'
}

var appSettingsTemp = functionAppKind == 'functionapp' ? union(commonAppSettings, windowsAppSettings) : commonAppSettings
var appSettings = contains(functionsWorkerRuntime, 'isolated') ? union(appSettingsTemp, isolatedAppSettings) : appSettingsTemp

var storagePrivateEndpoints = enableVnetIntegration ? [
  {
    name: replace(replace(nameConvPrivEndpoints, 'resourceName', storageAccountName), 'service', 'blob')
    privateDnsZoneId: storageBlobDnsZoneId 
    service: 'blob'
  }
  {
    name: replace(replace(nameConvPrivEndpoints, 'resourceName', storageAccountName), 'service', 'file')
    privateDnsZoneId: storageFileDnsZoneId
    service: 'file'
  }
  {
    name: replace(replace(nameConvPrivEndpoints, 'resourceName', storageAccountName), 'service', 'queue')
    privateDnsZoneId: storageQueueDnsZoneId
    service: 'queue'
  }
  {
    name: replace(replace(nameConvPrivEndpoints, 'resourceName', storageAccountName), 'service', 'table')
    privateDnsZoneId: storageTableDnsZoneId
    service: 'table'
  }
] : []

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: toLower(storageAccountName)
  location: location
  tags: contains(tags, 'Microsoft.Storage/storageAccounts') ? tags['Microsoft.Storage/storageAccounts'] : {}
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowedCopyScope: 'PrivateLink'
    allowCrossTenantReplication: false
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: false
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: true
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
        queue: {
          enabled: true
        }
        table: {
          enabled: true
        }
      }
    }
    largeFileSharesState: 'Enabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    publicNetworkAccess: enableVnetIntegration ? 'Disabled' : 'Enabled'
    sasPolicy: {
      expirationAction: 'Log'
      sasExpirationPeriod: '180.00:00:00'
    }
  }
  resource blobServices 'blobServices' = {
    name: 'default'
  }
  resource fileServices 'fileServices' = {
    name: 'default'
    resource fileShare 'shares' = {
      name: toLower(functionAppName)
      properties: {
        enabledProtocols: 'SMB'
        shareQuota: 5120
      }
    }
  }
}

resource storageAccount_privateEndpoints 'Microsoft.Network/privateEndpoints@2021-02-01' = [for (privateEndpoint, i) in storagePrivateEndpoints: if(enableVnetIntegration) {
  name: privateEndpoint.name
  location: location
  tags: contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {}
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${privateEndpoint.name}-connection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [privateEndpoint.service]          
        }
      }
    ]
    subnet: {
      id: storageAccountPrivateEndpointSubnetId
    }      
  }
}]

resource storageAccount_PrivateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = [for (privateEndpoint, i) in storagePrivateEndpoints: if(enableVnetIntegration) {
  name: '${privateEndpoint.name}-group'
  parent: storageAccount_privateEndpoints[i]
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${last(split(privateEndpoint.privateDnsZoneId, '/'))}-config'
        properties: {
          privateDnsZoneId: privateEndpoint.privateDnsZoneId
        }
      }
    ]
  }
}]

resource storageAccount_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(!empty(logAnalyticsWorkspaceId)) {
  name: '${storageAccountName}-diagnosticSettings'
  properties: {
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
  scope: storageAccount
}

resource storageAccount_blob_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(!empty(logAnalyticsWorkspaceId)) {
  name: '${storageAccountName}-logs'
  scope: storageAccount::blobServices
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'StorageWrite'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
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
    publicNetworkAccess: enablePublicAccess ? 'Enabled' : 'Disabled'
    serverFarmId: hostingPlanId // !empty(hostingPlanId) ? hostingPlanId : ( hostingPlanType != 'Consumption' ? hostingPlan.id : null )
    siteConfig: {
      linuxFxVersion: contains(functionAppKind, 'linux') ? '${linuxRuntimeStack}|${decimalRuntimeVersion}' : null
      netFrameworkVersion: !contains(functionAppKind, 'linux') && contains(runtimeStack, 'dotnet') ? 'v${decimalRuntimeVersion}' : null
    }
    virtualNetworkSubnetId: !empty(functionAppOutboundSubnetId) ? functionAppOutboundSubnetId : null
    vnetImagePullEnabled: enableVnetIntegration ? true : false
    vnetContentShareEnabled: enableVnetIntegration ? true : false
    vnetRouteAllEnabled: enableVnetIntegration ? true : false
  }
}

resource functionAppSettings 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'appsettings'
  kind: functionAppKind
  parent: functionApp
  properties: appSettings
}

resource functionApp_PrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = if(enableInboundPrivateEndpoint) {
  name: replace(replace(nameConvPrivEndpoints, 'resourceName', functionAppName), 'service', 'sites')
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
