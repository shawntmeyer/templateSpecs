@description('The location of all resources deployed by this template.')
param location string

@description('The name of the function App.')
param functionAppName string

@description('The type of site to deploy')
@allowed([
  'functionapp'       // function app windows os
  'functionapp,linux' // function app linux os
])
param functionAppKind string = 'functionapp,linux'

@description('The runtime stack used by the function App.')
@allowed([
  'dotnet'
  'dotnet-isolated'
  'java'
  'node'
  'powershell'
  'python'
])
param runtimeStack string = 'dotnet-isolated'

@description('The version of the runtime stack used by the function App.')
param runtimeVersion string = '6.0'

@description('The name of the service plan used by the function App.')
param functionHostingPlanName string = ''

@description('Indicates whether the function App should be accessible from the public network.')
param functionAppEnablePublicAccess bool = true

@description('The resource Id of the subnet used by the function App for inbound traffic.')
param functionAppInboundSubnetResourceId string = ''

@description('The resource Id of the private DNS Zone used by the function App.')
param functionAppPrivateDnsZoneResourceId string = ''

@description('The resource Id of the subnet used by the function App for outbound traffic.')
param functionAppOutputSubnetResourceId string

@description('The resource Id of the existing server farm to use for the function App.')
param hostingPlanExistingResourceId string = ''

@description('''When you create a function app in Azure, you must choose a hosting plan for your app.
There are three basic Azure Functions hosting plans provided by Azure Functions: Consumption plan, Premium plan, and Dedicated (App Service) plan. 
* Consumption: Scale automatically and only pay for compute resources when your functions are running.
* FunctionsPremium: Automatically scales based on demand using pre-warmed workers, which run applications with no delay after being idle, runs on more powerful instances, and connects to virtual networks.
* AppServicePlan: Best for long-running scenarios where Durable Functions can't be used. Consider an App Service plan in the following situations:
  * You have existing, underutilized VMs that are already running other App Service instances.
  * Predictive scaling and costs are required.
''')
@allowed([
  'Consumption'
  'FunctionsPremium'
  'AppServicePlan'
])
param hostingPlanType string = 'FunctionsPremium'

@allowed([
  'ElasticPremium_EP1'
  'Basic_B1'
  'Standard_S1'
  'PremiumV3_P1V3'
  'PremiumV3_P2V3'
  'PremiumV3_P3V3'
])
param hostingPlanPricing string = 'ElasticPremium_EP1'

@description('The resource Id of the Log Analytics workspace used for diagnostics.')
param logAnalyticsWorkspaceId string = ''

@description('The resource Id of the private Endpoint Subnet.')
param storagePrivateEndpointSubnetResourceId string

@description('The name of the storage account used by the function App.')
param storageAccountName string

@description('The resource Id of the blob storage Private DNS Zone.')
param storageBlobDnsZoneId string

@description('The resource Id of the file storage Private DNS Zone.')
param storageFileDnsZoneId string

@description('The resource Id of the queue storage Private DNS Zone.')
param storageQueueDnsZoneId string

@description('The resource Id of the table storage Private DNS Zone.')
param storageTableDnsZoneId string

@description('The tags to be assigned to the resources deployed by this template.')
param tags object = {}

var hostingPlanSku = {
  name: split(hostingPlanPricing, '_')[1]
  tier: split(hostingPlanPricing, '_')[0]
}

var commonAppSettings = {
  APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString
  APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsights.properties.InstrumentationKey
  AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  WEBSITE_CONTENTSHARE: toLower(functionAppName)
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: runtimeStack
}

var isolatedAppSettings = {
  WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED: '1'
}

var windowsAppSettings = {
  WEBSITE_NODE_DEFAULT_VERSION: '~${runtimeVersion}'
}

var appSettingsTemp = functionAppKind == 'functionapp' ? union(commonAppSettings, windowsAppSettings) : commonAppSettings
var appSettings = contains(runtimeStack, 'isolated') ? union(appSettingsTemp, isolatedAppSettings) : appSettingsTemp

var functionAppDiagnosticLogCategoriesToEnable = functionAppKind == 'functionapp' ? [
  'FunctionAppLogs'
] : [
  'AppServiceHTTPLogs'
  'AppServiceConsoleLogs'
  'AppServiceAppLogs'
  'AppServiceAuditLogs'
  'AppServiceIPSecAuditLogs'
  'AppServicePlatformLogs'
]

var diagnosticsLogsSpecified = [for category in functionAppDiagnosticLogCategoriesToEnable: {
  category: category
  enabled: true
  retentionPolicy: {
    enabled: true
    days: 30
  }
}]

var storagePrivateEndpoints = [
  {
    name: 'pe-${storageAccountName}-blob'
    privateDnsZoneId: storageBlobDnsZoneId 
    service: 'blob'
  }
  {
    name: 'pe-${storageAccountName}-file'
    privateDnsZoneId: storageFileDnsZoneId
    service: 'file'
  }
  {
    name: 'pe-${storageAccountName}-queue'
    privateDnsZoneId: storageQueueDnsZoneId
    service: 'queue'
  }
  {
    name: 'pe-${storageAccountName}-table'
    privateDnsZoneId: storageTableDnsZoneId
    service: 'table'
  }
]

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: contains(tags, 'Microsoft.Storage/storageAccounts') ? tags['Microsoft.Storage/storageAccounts'] : {}
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowedCopyScope: 'Blob'
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
    publicNetworkAccess: 'Disabled'
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

resource storageAccountPrivateEndpoints 'Microsoft.Network/privateEndpoints@2021-02-01' = [for (privateEndpoint, i) in storagePrivateEndpoints:{
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
      id: storagePrivateEndpointSubnetResourceId
    }      
  }
}]

resource storageAccountPrivateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = [for (privateEndpoint, i) in storagePrivateEndpoints:{
  name: '${privateEndpoint.name}-group'
  parent: storageAccountPrivateEndpoints[i]
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

resource hostingPlan 'Microsoft.Web/serverfarms@2023-01-01' = if (hostingPlanType != 'Consumption' && empty(hostingPlanExistingResourceId)) {
  name: functionHostingPlanName
  location: location
  sku: hostingPlanSku
  tags: contains(tags, 'Microsoft.Web/serverfarms') ? tags['Microsoft.Web/serverfarms'] : {}
  properties: {
    maximumElasticWorkerCount: functionAppKind == 'FunctionsPremium' ? 20 : null
    reserved: contains(functionAppKind, 'linux') ? true : false
  }
}

resource hostingPlan_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(hostingPlanType != 'Consumption' && empty(hostingPlanExistingResourceId)) {
  name: '${functionHostingPlanName}-diagnosticSettings'
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

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = if(!empty(logAnalyticsWorkspaceId)) {
  name: '${functionAppName}-insights'
  kind: 'web'
  location: location
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  kind: functionAppKind
  location: location
  tags: contains(tags, 'Microsoft.Web/sites') ? tags['Microsoft.Web/sites'] : {}
  properties: {
    publicNetworkAccess: functionAppEnablePublicAccess ? 'Enabled' : 'Disabled'
    serverFarmId: !empty(hostingPlanExistingResourceId) ? hostingPlanExistingResourceId : ( hostingPlanType != 'Consumption' ? hostingPlan.id : null )
    siteConfig: {
      linuxFxVersion: contains(functionAppKind, 'linux') ? '${runtimeStack}|${runtimeVersion}' : null
      netFrameworkVersion: !contains(functionAppKind, 'linux') && contains(runtimeStack, 'dotnet') ? 'v${runtimeVersion}' : null
    }
    virtualNetworkSubnetResourceId: functionAppOutputSubnetResourceId
    vnetContentShareEnabled: true
    vnetRouteAllEnabled: true
  }
}

resource functionAppSettings 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'appsettings'
  kind: functionAppKind
  parent: functionApp
  properties: appSettings
}

resource functionApp_PrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = if(!functionAppEnablePublicAccess) {
  name: 'pe-${functionAppName}-sites'
  location: location
  tags: contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {}
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
      id: functionAppEnablePublicAccess || empty(functionAppInboundSubnetResourceId) ? null : functionAppInboundSubnetResourceId 
    }      
  }
}

resource functionApp_PrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = if(!functionAppEnablePublicAccess) {
  name: 'pe-${functionAppName}-sites-group'
  parent: functionApp_PrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: !empty(functionAppPrivateDnsZoneResourceId) ? '${last(split(functionAppPrivateDnsZoneResourceId, '/'))}-config' : null
        properties: {
          privateDnsZoneId: functionAppEnablePublicAccess || empty(functionAppPrivateDnsZoneResourceId) ? null : functionAppPrivateDnsZoneResourceId
        }
      }
    ]
  }
}

resource functionApp_diagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${functionAppName}-diagnosticSettings'
  properties: {
    logs: diagnosticsLogsSpecified
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
  scope: functionApp
}
