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
param planId string
param storageAccountName string
param storageAccountPrivateEndpointSubnetId string
param storageBlobDnsZoneId string
param storageFileDnsZoneId string
param storageQueueDnsZoneId string
param storageTableDnsZoneId string
param tags object


var commonAppSettings = {
  APP_KIND: 'workflowApp'  
  AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  AzureFunctionsJobHost__extensionBundle__id: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
  AzureFunctionsJobHost__extensionBundle__version: '[1.*, 2.0.0)'
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: 'node'
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  WEBSITE_CONTENTSHARE: toLower(logicAppName)
  WEBSITE_NODE_DEFAULT_VERSION: '~18'
}

var appApplicationInsights = {
  APPLICATIONINSIGHTS_CONNECTION_STRING: enableApplicationInsights ? applicationInsights.properties.ConnectionString : null
}

var appSettings = enableApplicationInsights ? union(commonAppSettings, appApplicationInsights) : commonAppSettings

var storagePrivateEndpoints = enableStoragePrivateEndpoints ? [
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
    publicNetworkAccess: enableStoragePrivateEndpoints ? 'Disabled' : 'Enabled'
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
      name: toLower(logicAppName)
      properties: {
        enabledProtocols: 'SMB'
        shareQuota: 5120
      }
    }
  }
}

resource storageAccount_privateEndpoints 'Microsoft.Network/privateEndpoints@2021-02-01' = [for (privateEndpoint, i) in storagePrivateEndpoints: if(enableStoragePrivateEndpoints) {
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

resource storageAccount_PrivateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = [for (privateEndpoint, i) in storagePrivateEndpoints: if(enableStoragePrivateEndpoints) {
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
    serverFarmId: !empty(planId) ? planId : null
    siteConfig: {
      ftpsState: 'FtpsOnly'
      netFrameworkVersion: 'v6.0'
      use32BitWorkerProcess: false
    }
    virtualNetworkSubnetId: !empty(logicAppOutboundSubnetId) ? logicAppOutboundSubnetId : null
    vnetImagePullEnabled: enableStoragePrivateEndpoints ? true : false
    vnetContentShareEnabled: enableStoragePrivateEndpoints ? true : false
    vnetRouteAllEnabled: enableStoragePrivateEndpoints ? true : false
  }
}

resource logicAppSettings 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'appsettings'
  parent: logicApp
  properties: appSettings
}

resource logicApp_PrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = if(enableInboundPrivateEndpoint) {
  name: replace(replace(nameConvPrivEndpoints, 'resourceName', logicAppName), 'service', 'sites')
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
