@description('The location of all resources deployed by this template.')
param location string

@description('The kind of the App Service Plan used by the function App.')
@allowed([
  'App'
  'Elastic'
  'FunctionApp'
  'Windows'
  'Linux'
])
param appServicePlanKind string

@description('The name of the function App.')
param functionAppName string

@description('The type of site to deploy')
@allowed([
  'functionapp' // function app windows os
  'functionapp,linux' // function app linux os
])
param functionAppKind string = 'functionapp,linux'

@description('The name of the file share used by the function App.')
param functionAppFileShareName string

@description('The name of the service plan used by the function App.')
param functionAppServicePlanName string

@description('Indicates whether the function App should be accessible from the public network.')
param functionAppEnablePublicAccess bool = true

@description('The resource Id of the subnet used by the function App for inbound traffic.')
param functionAppInboundVnetSubnetId string

@description('The resource Id of the private DNS Zone used by the function App.')
param functionAppPrivateDnsZoneResourceId string

@description('The resource Id of the subnet used by the function App for outbound traffic.')
param functionAppOutboundVnetSubnetId string

@description('The resource Id of the Log Analytics workspace used for diagnostics.')
param logAnalyticsWorkspaceId string

@description('The name of the .NET Framework version used by the function App.')
param netFrameworkVersion string = 'v8.0'

@description('The resource Id of the private Endpoint Subnet.')
param storagePrivateEndpointSubnetId string

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
param tags object

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
  resource fileServices 'fileServices' = {
    name: 'default'
    resource fileShare 'shares' = {
      name: functionAppFileShareName
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
      id: storagePrivateEndpointSubnetId
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

resource storageAccount_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${storageAccountName}-diagnosticSettings'
  properties: {
    logs: [
      {
        category: 'Storage'
        enabled: true
      }
    ]
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

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: functionAppServicePlanName
  kind: appServicePlanKind
  location: location
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
  }
  tags: contains(tags, 'Microsoft.Web/serverfarms') ? tags['Microsoft.Web/serverfarms'] : {}
  properties: {
    maximumElasticWorkerCount: 20
    reserved: appServicePlanKind == 'Linux'
    targetWorkerCount: 0
    zoneRedundant: false
  }
}

resource appServicePlan_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${functionAppServicePlanName}-diagnosticSettings'
  properties: {
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
  scope: appServicePlan
}

resource functionAppInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: functionAppName
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
    serverFarmId: appServicePlan.id  
    siteConfig: {
      appSettings: [
        /*
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
        */
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~14'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: functionAppInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: functionAppInsights.properties.ConnectionString
        }
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
          value: functionAppFileShareName
        }
      ]
      netFrameworkVersion: !empty(netFrameworkVersion) ? netFrameworkVersion : null
    }
    virtualNetworkSubnetId: functionAppOutboundVnetSubnetId
    vnetContentShareEnabled: true
    vnetRouteAllEnabled: true
  }
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
      id: functionAppEnablePublicAccess ? null : functionAppInboundVnetSubnetId 
    }      
  }
}

resource functionApp_PrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = if(!functionAppEnablePublicAccess) {
  name: 'pe-${functionAppName}-sites-group'
  parent: functionApp_PrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${last(split(functionAppPrivateDnsZoneResourceId, '/'))}-config'
        properties: {
          privateDnsZoneId: functionAppEnablePublicAccess ? null : functionAppPrivateDnsZoneResourceId
        }
      }
    ]
  }
}

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



