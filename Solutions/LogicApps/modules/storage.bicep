param deployStorageAccount bool
param enableStoragePrivateEndpoints bool
param fileShareName string
param location string
param logAnalyticsWorkspaceId string
param nameConvPrivEndpoints string
param storageAccountId string
param storageAccountName string
param storageAccountPrivateEndpointSubnetId string
param storageAccountSku string
param storageBlobDnsZoneId string
param storageFileDnsZoneId string
param storageQueueDnsZoneId string
param storageTableDnsZoneId string
param tags object

var storageAccountNameVar = deployStorageAccount ? storageAccountName : last(split(storageAccountId, '/'))

var storagePrivateEndpoints = enableStoragePrivateEndpoints ? [
  {
    name: replace(replace(replace(nameConvPrivEndpoints, 'resourceName', storageAccountNameVar), 'service', 'blob'), '-uniqueString', '.${uniqueString(storageAccountPrivateEndpointSubnetId)}')
    privateDnsZoneId: storageBlobDnsZoneId 
    service: 'blob'
  }
  {
    name: replace(replace(replace(nameConvPrivEndpoints, 'resourceName', storageAccountNameVar), 'service', 'file'), '-uniqueString', '.${uniqueString(storageAccountPrivateEndpointSubnetId)}')
    privateDnsZoneId: storageFileDnsZoneId
    service: 'file'
  }
  {
    name: replace(replace(replace(nameConvPrivEndpoints, 'resourceName', storageAccountNameVar), 'service', 'queue'), '-uniqueString', '.${uniqueString(storageAccountPrivateEndpointSubnetId)}')
    privateDnsZoneId: storageQueueDnsZoneId
    service: 'queue'
  }
  {
    name: replace(replace(replace(nameConvPrivEndpoints, 'resourceName', storageAccountNameVar), 'service', 'table'), '-uniqueString', '.${uniqueString(storageAccountPrivateEndpointSubnetId)}')
    privateDnsZoneId: storageTableDnsZoneId
    service: 'table'
  }
] : []

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = if(deployStorageAccount) {
  name: storageAccountNameVar
  location: location
  tags: contains(tags, 'Microsoft.Storage/storageAccounts') ? tags['Microsoft.Storage/storageAccounts'] : {}
  sku: {
    name: storageAccountSku
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
  }
}

resource newAccountFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = if(deployStorageAccount) {
  name: fileShareName
  parent: storageAccount::fileServices
  properties: {
    enabledProtocols: 'SMB'
    shareQuota: 5120
  }
}

resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = if(!deployStorageAccount && !empty(storageAccountId)) {
  name: storageAccountNameVar
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = if(!deployStorageAccount && !empty(storageAccountId)) {
  name: 'default'
  parent: existingStorageAccount
}

resource existingAccountFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = if(!deployStorageAccount && !empty(storageAccountId)) {
  name: fileShareName
  parent: fileServices
  properties: {
    enabledProtocols: 'SMB'
    shareQuota: 5120
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
          privateLinkServiceId: deployStorageAccount ? storageAccount.id : existingStorageAccount.id
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

resource storageAccount_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(deployStorageAccount && !empty(logAnalyticsWorkspaceId)) {
  name: '${storageAccountName}-diagnosticSettings'
  scope: storageAccount
  properties: {
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
}

resource storageAccount_blob_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(deployStorageAccount && !empty(logAnalyticsWorkspaceId)) {
  name: '${storageAccountName}-blob-diagnosticSettings'
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

output storageAccountResourceId string = deployStorageAccount ? storageAccount.id : existingStorageAccount.id
