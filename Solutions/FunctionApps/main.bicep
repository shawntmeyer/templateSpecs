// Basics

@description('Optional. The location of all resources deployed by this template.')
param location string = resourceGroup().location

@description('Required. The name of the function App.')
param functionAppName string

@description('Optional. The type of site to deploy')
@allowed([
  'functionapp'       // function app windows os
  'functionapp,linux' // function app linux os
])
param functionAppKind string = 'functionapp,linux'

@description('Optional. The runtime stack used by the function App.')
@allowed([
  'dotnet'
  'dotnet-isolated'
  'java'
  'node'
  'powershell'
  'python'
])
param runtimeStack string = 'dotnet-isolated'

@description('Optional. The version of the runtime stack used by the function App. The version must be compatible with the runtime stack.')
param runtimeVersion string = '6.0'

// Hosting Plan

@description('''Optional. When you create a function app in Azure, you must choose a hosting plan for your app.
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

@description('Conditional. The resource Id of the existing server farm to use for the function App.')
param hostingPlanExistingResourceId string = ''

@description('Conditional. The name of the service plan used by the function App. Not used when "hostingPlanExistingResourceId" is provided or hostingPlanType is set to "Consumption".')
param functionHostingPlanName string = ''

@description('Optional. The hosting plan pricing plan. Not used when "hostingPlanExistingResourceId" is provided or hostingPlanType is set to "Consumption".')
@allowed([
  'ElasticPremium_EP1'
  'Basic_B1'
  'Standard_S1'
  'PremiumV3_P1V3'
  'PremiumV3_P2V3'
  'PremiumV3_P3V3'
])
param hostingPlanPricing string = 'ElasticPremium_EP1'

@description('Required. The name of the storage account used by the function App.')
param storageAccountName string

// Monitoring
@description('Optional. To enable diagnostics settings, provide the resource Id of the Log Analytics workspace where logs are to be sent.')
param logAnalyticsWorkspaceId string = ''

// Networking

@description('Indicates whether outbound traffic from the function App should be routed through a private endpoint.')
param enableNetworkInjection bool = true

@description('Indicates whether the function App should be accessible from the public network.')
param enablePublicAccess bool = true

//  existing Subnets

@description('Conditional. The resource Id of the subnet used by the function App for inbound traffic. Required when "enablePublicAccess" is set to false and you aren\'t creating a new vnet and subnets.')
param functionAppInboundSubnetId string = ''

@description('Conditional. The resource Id of the subnet used by the function App for outbound traffic. Required when "enableNetworkInjection" is set to true and you aren\'t creating a new vnet and subnets.')
param functionAppOutboundSubnetId string = ''

@description('Conditional The resource Id of the private Endpoint Subnet. Required when "enableNetworkInjection" is set to true and you aren\'t creating a new vnet and subnets.')
param storagePrivateEndpointSubnetId string = ''

//  new Virtual Network (only used when the existing subnets aren't specified. Fill in all values where needed.)

@description('Conditional. The name of the virtual network used for Virtual Network Integration. Required when "enableNetworkInjection" is set to true and you aren\'t providing the resource Id of an existing virtual network.')
param vnetName string = ''

@description('Optional. The address prefix of the virtual network used Virtual Network Integration.')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Optional. The name of the subnet used by the function App for Virtual Network Integration.')
param functionAppOutboundSubnetName string = 'fa-outbound-subnet'

@description('Optional. The address prefix of the subnet used by the function App for Virtual Network Integration.')
param functionAppOutboundSubnetAddressPrefix string = '10.0.0.0/24'

@description('Optional. The name of the subnet used for private Endpoints.')
param storagePrivateEndpointSubnetName string = 'storage-subnet'

@description('Optional. The address prefix of the subnet used for private Endpoints.')
param storagePrivateEndpointSubnetAddressPrefix string = '10.0.1.0/24'

//  only required when EnablePublicAccess is set to false
@description('Optional. The name of the subnet used by the function App for inbound access when public access is disabled.')
param functionAppInboundSubnetName string = 'fa-inbound-subnet'

@description('Optional. The address prefix of the subnet used by the function App for inbound access when public access is disabled.')
param functionAppInboundSubnetAddressPrefix string = '10.0.2.0/24'

// Private DNS Zones

@description('Conditional. The resource Id of the function app private DNS Zone. Required when "enablePublicAccess" is set to false.')
param functionAppPrivateDnsZoneResourceId string = ''

@description('Conditional. The resource Id of the blob storage Private DNS Zone. Required when "enableNetworkInjection" is set to true.')
param storageBlobDnsZoneId string = ''

@description('Conditional. The resource Id of the file storage Private DNS Zone. Required when "enableNetworkInjection" is set to true.')
param storageFileDnsZoneId string = ''

@description('Conditional. The resource Id of the queue storage Private DNS Zone. Required when "enableNetworkInjection" is set to true.')
param storageQueueDnsZoneId string = ''

@description('Conditional. The resource Id of the table storage Private DNS Zone. Required when "enableNetworkInjection" is set to true.')
param storageTableDnsZoneId string = ''

// tags

@description('''
Optional. The tags to be assigned to the resources deployed by this template.
Must be provided in the following 'TagsByResource' format: (JSON)
{
  "Microsoft.Storage/storageAccounts": {
    "key1": "value1",
    "key2": "value2"
  },
  "Microsoft.Web/sites": {
    "key1": "value1",
    "key2": "value2"
  },
  "Microsoft.Web/serverfarms": {
    "key1": "value1",
    "key2": "value2"
  },
  {
    "Microsoft.Network/privateEndpoints" : {
      "key1": "value1",
      "key2": "value2"
    }
  },
  {
    "Microsoft.Network/virtualNetworks" : {
      "key1": "value1",
      "key2": "value2"
    }
  }
}
''')
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

var storagePrivateEndpoints = enableNetworkInjection ? [
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
] : []

var subnetsCommon = [
  {
    name: functionAppOutboundSubnetName
    properties: {
      privateEndpointNetworkPolicies: 'Enabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      delegations: [
        {
          name: 'webapp'
          properties: {
            serviceName: 'Microsoft.Web/serverFarms'
          }
        }
      ]
      addressPrefix: functionAppOutboundSubnetAddressPrefix
    }
  }
  {
    name: storagePrivateEndpointSubnetName
    properties: {
      privateEndpointNetworkPolicies: 'Disabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      addressPrefix: storagePrivateEndpointSubnetAddressPrefix
    }
  }
]

var subnetsPublicAccessDisabled = [
  {
    name: functionAppInboundSubnetName
    properties: {
      privateEndpointNetworkPolicies: 'Disabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      addressPrefix: functionAppInboundSubnetAddressPrefix
    }
  }
]

resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' = if( enableNetworkInjection && !empty(vnetName) ) {
  name: !empty(vnetName) ? vnetName : 'vnet-${functionAppName}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: enablePublicAccess ? subnetsCommon : union(subnetsCommon, subnetsPublicAccessDisabled)
  }
}

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
    publicNetworkAccess: enableNetworkInjection ? 'Disabled' : 'Enabled'
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

resource storageAccount_privateEndpoints 'Microsoft.Network/privateEndpoints@2021-02-01' = [for (privateEndpoint, i) in storagePrivateEndpoints: if(enableNetworkInjection) {
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
      id: !empty(storagePrivateEndpointSubnetId) ? storagePrivateEndpointSubnetId : vnet.properties.subnets[1].id
    }      
  }
}]

resource storageAccount_PrivateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = [for (privateEndpoint, i) in storagePrivateEndpoints: if(enableNetworkInjection) {
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
    publicNetworkAccess: enablePublicAccess ? 'Enabled' : 'Disabled'
    serverFarmId: !empty(hostingPlanExistingResourceId) ? hostingPlanExistingResourceId : ( hostingPlanType != 'Consumption' ? hostingPlan.id : null )
    siteConfig: {
      linuxFxVersion: contains(functionAppKind, 'linux') ? '${runtimeStack}|${runtimeVersion}' : null
      netFrameworkVersion: !contains(functionAppKind, 'linux') && contains(runtimeStack, 'dotnet') ? 'v${runtimeVersion}' : null
    }
    virtualNetworkSubnetId: enableNetworkInjection ? (!empty(functionAppOutboundSubnetId) ? functionAppOutboundSubnetId : vnet.properties.subnets[0].id) : null
    vnetImagePullEnabled: enableNetworkInjection ? true : false
    vnetContentShareEnabled: enableNetworkInjection ? true : false
    vnetRouteAllEnabled: enableNetworkInjection ? true : false
  }
}

resource functionAppSettings 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'appsettings'
  kind: functionAppKind
  parent: functionApp
  properties: appSettings
}

resource functionApp_PrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = if(!enablePublicAccess) {
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
      id: enablePublicAccess ? null : !empty(functionAppInboundSubnetId) ? functionAppInboundSubnetId : vnet.properties.subnets[2].id
    }      
  }
}

resource functionApp_PrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = if(!enablePublicAccess) {
  name: 'pe-${functionAppName}-sites-group'
  parent: functionApp_PrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: !empty(functionAppPrivateDnsZoneResourceId) ? '${last(split(functionAppPrivateDnsZoneResourceId, '/'))}-config' : null
        properties: {
          privateDnsZoneId: enablePublicAccess || empty(functionAppPrivateDnsZoneResourceId) ? null : functionAppPrivateDnsZoneResourceId
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
