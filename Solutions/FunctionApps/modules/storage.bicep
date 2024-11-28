param containerName string
param deployStorageAccount bool
param enableStoragePrivateEndpoints bool
param fileShareName string
param hostPlanType string
param location string
param logAnalyticsWorkspaceId string
param privateEndpointNameConv string
param privateEndpointNICNameConv string
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
var vnetName = !empty(storageAccountPrivateEndpointSubnetId) ? split(storageAccountPrivateEndpointSubnetId, '/')[8] : ''
var privateEndpointName = length(replace(
  replace(privateEndpointNameConv, 'RESOURCENAME', storageAccountName),
  'VNET',
  vnetName
)) > 66 ? replace(
  replace(privateEndpointNameConv, 'RESOURCENAME', replace(storageAccountNameVar, '-', '')),
  'VNET',
  replace(vnetName, '-', '')
) : replace(
  replace(privateEndpointNameConv, 'RESOURCENAME', storageAccountNameVar),
  'VNET',
  vnetName
)

var privateEndpointNICName = length(replace(
  replace(privateEndpointNICNameConv, 'RESOURCENAME', storageAccountNameVar),
  'VNET',
  vnetName
)) > 82 ? replace(
  replace(privateEndpointNICNameConv, 'RESOURCENAME', replace(storageAccountNameVar, '-', '')),
  'VNET',
  replace(vnetName, '-', '')
) : replace(
  replace(privateEndpointNICNameConv, 'RESOURCENAME', storageAccountNameVar),
  'VNET',
  vnetName
)


var blobPE = !empty(storageBlobDnsZoneId) ? [{
  customNICName: replace(privateEndpointNICName, 'SERVICE', 'blob')
  name: replace(privateEndpointName, 'SERVICE', 'blob')
  privateDnsZoneId: storageBlobDnsZoneId
  service: 'blob'
}] : []
var filePE = !empty(storageFileDnsZoneId) ? [{
  customNICName: replace(privateEndpointNICName, 'SERVICE', 'file')
  name: replace(privateEndpointName, 'SERVICE', 'file')
  privateDnsZoneId: storageFileDnsZoneId
  service: 'file'
}] : []
var queuePE = !empty(storageQueueDnsZoneId) ? [{
  customNICName: replace(privateEndpointNICName, 'SERVICE', 'queue')
  name: replace(privateEndpointName, 'SERVICE', 'queue')
  privateDnsZoneId: storageQueueDnsZoneId
  service: 'queue'
}] : []
var tablePE = !empty(storageTableDnsZoneId) ? [{
  customNICName: replace(privateEndpointNICName, 'SERVICE', 'table')
  name: replace(privateEndpointNICName, 'SERVICE', 'table')
  privateDnsZoneId: storageTableDnsZoneId
  service: 'table'
}] : []
var storageAccountPrivateEndpoints = enableStoragePrivateEndpoints && !empty(vnetName) ? union(blobPE, filePE, queuePE, tablePE) : []

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
    allowSharedKeyAccess: hostPlanType != 'AppServicePlan' && hostPlanType != 'FlexConsumption' ? true : false
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
    networkAcls: enableStoragePrivateEndpoints ? {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    } : null
    publicNetworkAccess: enableStoragePrivateEndpoints ? 'Disabled' : 'Enabled'
    sasPolicy: {
      expirationAction: 'Log'
      sasExpirationPeriod: '180.00:00:00'
    }
  }
  resource blobServices 'blobServices' = {
    name: 'default'    
  }
  resource fileServices 'fileServices' = if(!empty(fileShareName)) {
    name: 'default'
  }  
}

resource shareNewAccount 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = if(deployStorageAccount && !empty(fileShareName)) {
  name: fileShareName
  parent: storageAccount::fileServices
  properties: {
    enabledProtocols: 'SMB'
    shareQuota: 5120
  }
}

resource blobContainerNewAccount 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = if (deployStorageAccount && !empty(containerName)) {
  name: containerName
  parent: storageAccount::blobServices
  properties: {
    publicAccess: 'None'
  }
}

resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = if(!deployStorageAccount && !empty(storageAccountId)) {
  name: storageAccountNameVar
}

resource fileServicesExistingAccount 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = if(!deployStorageAccount && !empty(storageAccountId) && !empty(fileShareName)) {
  name: 'default'
  parent: existingStorageAccount
}

resource fileShareExistingAccount 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = if(!deployStorageAccount && !empty(storageAccountId) && !empty(fileShareName)) {
  name: fileShareName
  parent: fileServicesExistingAccount
  properties: {
    enabledProtocols: 'SMB'
    shareQuota: 5120
  }
}

resource blobServicesExistingAccount 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = if(!deployStorageAccount && !empty(storageAccountId) && !empty(containerName)) {
  name: 'default'
  parent: existingStorageAccount
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = if(!deployStorageAccount && !empty(storageAccountId) && !empty(containerName)) {
  name: containerName
  parent: blobServicesExistingAccount
  properties: {
    publicAccess: 'None'
  }
}

resource storageAccount_privateEndpoints 'Microsoft.Network/privateEndpoints@2023-05-01' = [for (privateEndpoint, i) in storageAccountPrivateEndpoints: if(enableStoragePrivateEndpoints) {
  name: privateEndpoint.name
  location: location
  tags: tags[?'Microsoft.Network/privateEndpoints'] ?? {}
  properties: {
    customNetworkInterfaceName: privateEndpoint.customNICName
    privateLinkServiceConnections: [
      {
        name: privateEndpoint.name
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

resource storageAccount_PrivateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = [for (privateEndpoint, i) in storageAccountPrivateEndpoints: if(enableStoragePrivateEndpoints && !empty(storageAccountPrivateEndpoints[i].privateDnsZoneId)) {
  name: privateEndpoint.name
  parent: storageAccount_privateEndpoints[i]
  properties: {
    privateDnsZoneConfigs: [
      {
        name: !empty(privateEndpoint.privateDnsZoneId) ? '${last(split(privateEndpoint.privateDnsZoneId, '/'))}-config' : ''
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
