param containerName string
param deployStorageAccount bool
param enableStoragePrivateEndpoints bool
param fileShareName string
param hostPlanType string?
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
var storageAccountPrivateEndpoints = enableStoragePrivateEndpoints ? [
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
  tags: tags[?'Microsoft.Storage/storageAccounts'] ?? {}
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

resource shareNewAccount 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = if(deployStorageAccount && hostPlanType != 'FlexConsumption') {
  name: fileShareName
  parent: storageAccount::fileServices
  properties: {
    enabledProtocols: 'SMB'
    shareQuota: 5120
  }
}

resource blobContainerNewAccount 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = if (deployStorageAccount && hostPlanType == 'FlexConsumption') {
  name: containerName
  parent: storageAccount::blobServices
  properties: {
    publicAccess: 'None'
  }
}

resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = if(!deployStorageAccount && !empty(storageAccountId)) {
  name: storageAccountNameVar
}

resource fileServicesExistingAccount 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = if(!deployStorageAccount && !empty(storageAccountId) && hostPlanType != 'FlexConsumption') {
  name: 'default'
  parent: existingStorageAccount
}

resource fileShareExistingAccount 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = if(!deployStorageAccount && !empty(storageAccountId) && hostPlanType != 'FlexConsumption') {
  name: fileShareName
  parent: fileServicesExistingAccount
  properties: {
    enabledProtocols: 'SMB'
    shareQuota: 5120
  }
}

resource blobServicesExistingAccount 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = if(!deployStorageAccount && !empty(storageAccountId) && hostPlanType == 'FlexConsumption') {
  name: 'default'
  parent: existingStorageAccount
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = if(!deployStorageAccount && !empty(storageAccountId) && hostPlanType == 'FlexConsumption') {
  name: containerName
  parent: blobServicesExistingAccount
  properties: {
    publicAccess: 'None'
  }
}

resource storageAccount_privateEndpoints 'Microsoft.Network/privateEndpoints@2021-02-01' = [for (privateEndpoint, i) in storageAccountPrivateEndpoints: if(enableStoragePrivateEndpoints) {
  name: privateEndpoint.name
  location: location
  tags: tags[?'Microsoft.Network/privateEndpoints'] ?? {}
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

resource storageAccount_PrivateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = [for (privateEndpoint, i) in storageAccountPrivateEndpoints: if(enableStoragePrivateEndpoints) {
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
