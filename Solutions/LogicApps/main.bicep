// Basics
targetScope = 'subscription'

@description('The location of all resources deployed by this template.')
param location string

@description('Optional. Reverse the order of the resource type and name in the generated resource name. Default is false.')
param nameConvResTypeAtEnd bool = false

@description('Required. The name of the function App.')
param logicAppName string

@description('Required. The name of the resource group where the function App will be deployed.')
param logicAppResourceGroupName string

// Hosting Plan

@description('Required. Determines whether or not a new host plan is deployed. If set to false and the host plan type is not "Consumption", then the "hostingPlanId" parameter must be provided.')
param deployHostingPlan bool

@description('''Optional. When you create a logic app in Azure, you must choose a hosting plan for your app.
There are two basic hosting plans provided by Azure for logic apps: Consumption or Standard plans. 
* Consumption: Best for entry-level. Pay only as much as your workflow runs.
* Standard: Best for enterprise-level, serverless applications, with event-based scaling and networking isolation.
''')
@allowed([
  'Consumption'
  'Standard'
])
param hostingPlanType string = 'Standard'

@description('Conditional. The resource Id of the existing server farm to use for the function App.')
param hostingPlanId string = ''

@description('Conditional. The name of the service plan used by the function App. Not used when "hostingPlanId" is provided or hostingPlanType is set to "Consumption".')
param hostingPlanName string = ''

@description('Conditional. The name of the resource Group where the hosting plan will be deployed. Not used when "hostingPlanId" is provided or hostingPlanType is set to "Consumption".')
param hostingPlanResourceGroupName string = ''

@description('Optional. The hosting plan pricing plan. Not used when "hostingPlanId" is provided or hostingPlanType is set to "Consumption".')
@allowed([
  'WorkflowStandard_WS1'
  'WorkflowStandard_WS2'
  'WorkflowStandard_WS3'
])
param hostingPlanPricing string = 'WorkflowStandard_WS1'

@description('Optional. Determines if the hosting plan is zone redundant. Not used when "hostingPlanId" is provided or hostingPlanType is set to "Consumption".')
param hostingPlanZoneRedundant bool = false

@description('Optional. Determines whether an existing storage account is used or a new one is deployed. If set to true, the "storageAccountName" parameter must be provided. If set to false, the "storageAccountId" parameter must be provided.')
param deployStorageAccount bool = true

@description('Conditional. The resource Id of the existing storage account to be used with the logic app.')
param storageAccountId string = ''

@description('Conditional. The name of the storage account used by the logic app. Required if "deployStorageAccount" is set to true.')
param storageAccountName string = ''

// Monitoring

@description('Optional. Enable Application Insights for the function App.')
param enableApplicationInsights bool = true

@description('Optional. To enable diagnostics settings, provide the resource Id of the Log Analytics workspace where logs are to be sent.')
param logAnalyticsWorkspaceId string = ''

// Networking

@description('Optional. Indicates whether the function App should be accessible from the public network.')
param enablePublicAccess bool = true

@description('Optional. Indicates whether the function App should be accessible via a private endpoint.')
param enableInboundPrivateEndpoint bool = false

@description('Optional. Indicates whether outbound traffic from the function App should be routed through a private endpoint.')
param enableVnetIntegration bool = true

@description('Optional. Indicates whether a new Vnet and associated resources should be deployed to support the hosting plan and function app.')
param deployNetworking bool = false

//  existing Subnets

@description('Conditional. The resource Id of the subnet used by the function App for inbound traffic. Required when "enableInboundPrivateEndpoint" is set to false and you aren\'t creating a new vnet and subnets.')
param logicAppInboundSubnetId string = ''

@description('Conditional. The resource Id of the subnet used by the function App for outbound traffic. Required when "enableVnetIntegration" is set to true and you aren\'t creating a new vnet and subnets.')
param logicAppOutboundSubnetId string = ''

@description('Conditional The resource Id of the private Endpoint Subnet. Required when "enableVnetIntegration" is set to true and you aren\'t creating a new vnet and subnets.')
param storagePrivateEndpointSubnetId string = ''

//  new Virtual Network (only used when the existing subnets aren't specified. Fill in all values where needed.)

@description('Conditional. The name of the virtual network used for Virtual Network Integration. Required when "enableVnetIntegration" is set to true and "deployNetworking" = true.')
param vnetName string = ''

@description('Conditional. The name of the resource group where the virtual network is deployed. Required when "enableVnetIntegration" is set to true and "deployNetworking" = true.')
param networkingResourceGroupName string = ''

@description('Optional. The address prefix of the virtual network used Virtual Network Integration.')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Optional. The name of the subnet used by the function App for Virtual Network Integration. Used when "enableVnetIntegration" is set to true and "deployNetworking" = true.')
param logicAppOutboundSubnetName string = 'fa-outbound-subnet'

@description('Optional. The address prefix of the subnet used by the function App for Virtual Network Integration. Used when "enableVnetIntegration" is set to true and "deployNetworking" = true.')
param logicAppOutboundSubnetAddressPrefix string = '10.0.0.0/24'

@description('Optional. Determines whether private endpoints are used on the function app storage account. Used when "enableVnetIntegration" is set to true.')
param enableStoragePrivateEndpoints bool = true

@description('Optional. The name of the subnet used for private Endpoints. Used when "enableVnetIntegration", "enableStoragePrivateEndpoints", and "deployNetworking" are all set to  "true".')
param storagePrivateEndpointSubnetName string = 'storage-subnet'

@description('Optional. The address prefix of the subnet used for private Endpoints. Used when "enableVnetIntegration", "enableStoragePrivateEndpoints", and "deployNetworking" are all set to  "true".')
param storagePrivateEndpointSubnetAddressPrefix string = '10.0.1.0/24'

//  only required when enableInboundPrivateEndpoint is set to false
@description('Optional. The name of the subnet used by the function App for inbound access when public access is disabled. Used when "enableInboundPrivateEndpoint" and "deployNetworking" = true.')
param logicAppInboundSubnetName string = 'fa-inbound-subnet'

@description('Optional. The address prefix of the subnet used by the function App for inbound access when public access is disabled. Used when "enableInboundPrivateEndpoint" and "deployNetworking" = true.')
param logicAppInboundSubnetAddressPrefix string = '10.0.2.0/24'

// Private DNS Zones

@description('Conditional. The resource Id of the function app private DNS Zone. Required when "enableInboundPrivateEndpoint" = true and "deployNetworking" = false.')
param logicAppPrivateDnsZoneId string = ''

@description('Conditional. The resource Id of the blob storage Private DNS Zone. Required when "enableVnetIntegration" and "enableStoragePrivateEndpoints" = true and "deployNetworking = false.')
param storageBlobDnsZoneId string = ''

@description('Conditional. The resource Id of the file storage Private DNS Zone. Required when "enableVnetIntegration" and "enableStoragePrivateEndpoints" = true and "deployNetworking = false.')
param storageFileDnsZoneId string = ''

@description('Conditional. The resource Id of the queue storage Private DNS Zone. Required when "enableVnetIntegration" and "enableStoragePrivateEndpoints" = true and "deployNetworking = false.')
param storageQueueDnsZoneId string = ''

@description('Conditional. The resource Id of the table storage Private DNS Zone. Required when "enableVnetIntegration" and "enableStoragePrivateEndpoints" = true and "deployNetworking = false.')
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

@description('Do not change. Used for deployment naming.')
param timestamp string = utcNow('yyyyMMddhhmmss')

var locations = (loadJsonContent('../../data/locations.json'))[environment().name]
var resourceAbbreviations = loadJsonContent('../../data/resourceAbbreviations.json')

var nameConvPrivEndpoints = nameConvResTypeAtEnd ? 'resourceName-service-${locations[location].abbreviation}-${resourceAbbreviations.privateEndpoints}-uniqueString' : '${resourceAbbreviations.privateEndpoints}-resourceName-service-${locations[location].abbreviation}-uniqueString'

var subnetOutbound = enableVnetIntegration ? [
  {
    name: logicAppOutboundSubnetName
    properties: {
      delegations: [
        {
          name: 'webapp'
          properties: {
            serviceName: 'Microsoft.Web/serverFarms'
          }
        }
      ]
      addressPrefix: logicAppOutboundSubnetAddressPrefix
    }
  }
] : []

var subnetStoragePrivateEndpoints = enableStoragePrivateEndpoints ? [
  {
    name: storagePrivateEndpointSubnetName
    properties: {
      privateEndpointNetworkPolicies: 'Disabled'
      addressPrefix: storagePrivateEndpointSubnetAddressPrefix
    }
  }
] : []

var subnetInboundPrivateEndpoint = enableInboundPrivateEndpoint ? [
  {
    name: logicAppInboundSubnetName
    properties: {
      privateEndpointNetworkPolicies: 'Disabled'
      addressPrefix: logicAppInboundSubnetAddressPrefix
    }
  }
] : []

var storagePrivateDnsZoneNames =  enableStoragePrivateEndpoints ? [
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.file.${environment().suffixes.storage}'
  'privatelink.queue.${environment().suffixes.storage}'
  'privatelink.table.${environment().suffixes.storage}'
] : []

var websiteSuffixes = {
  azurecloud: 'azurewebsites.net'
  azureusgovernment: 'azurewebsites.us'
  usnat: 'azurewebsites.eaglex.ic.gov'
}

var webSitePrivateDnsZoneName = enableInboundPrivateEndpoint ? [
  'privatelink.${websiteSuffixes[environment().name]}'
] : []

// ensure that no resource Group Names are blank for deployments
var resourceGroupNameLogicApp = logicAppResourceGroupName
var resourceGroupNamePlan = !empty(hostingPlanResourceGroupName) ? hostingPlanResourceGroupName : resourceGroupNameLogicApp
var resourceGroupNameNetworking = !empty(networkingResourceGroupName) ? networkingResourceGroupName : resourceGroupNameLogicApp
var resourceGroupNameStorage = !empty(storageAccountId) && !deployStorageAccount ? split(storageAccountId, '/')[4] : resourceGroupNameLogicApp

var resourceGroupNames = [
  resourceGroupNameNetworking
  resourceGroupNamePlan
  resourceGroupNameLogicApp  
]

var storageAccountSku = deployHostingPlan ? ( hostingPlanZoneRedundant ? 'Standard_ZRS' : 'Standard_LRS' ) : ( existingPlan.properties.numberOfWorkers > 1 ? 'Standard_ZRS' : 'Standard_LRS' )

resource rgs 'Microsoft.Resources/resourceGroups@2023-07-01' = [for resourceGroupName in union(resourceGroupNames, resourceGroupNames): {
  name: resourceGroupName
  location: location
}]

module workflow 'modules/workflow.bicep' = if(hostingPlanType == 'Consumption') {
  name: 'workflow-${timestamp}'
  scope: resourceGroup(resourceGroupNameLogicApp)
  params: {
    workflowName: logicAppName
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    zoneRedundancy: hostingPlanZoneRedundant ? 'Enabled' : ''
    tags: tags
  }
  dependsOn: [
    rgs
  ]
}

module networking 'modules/networking.bicep' = if(hostingPlanType == 'Standard' && deployNetworking && (enableVnetIntegration || enableInboundPrivateEndpoint)) {
  name: 'networking-resources-${timestamp}'
  scope: resourceGroup(resourceGroupNameNetworking)
  params: {
    location: location
    privateDnsZoneNames: union(storagePrivateDnsZoneNames, webSitePrivateDnsZoneName)
    subnets: union(subnetOutbound, subnetStoragePrivateEndpoints, subnetInboundPrivateEndpoint)
    timestamp: timestamp
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    tags: tags
  }
  dependsOn: [
    rgs
  ]
}

module hostingPlan 'modules/hostingPlan.bicep' = if(hostingPlanType == 'Standard' && deployHostingPlan) {
  name: 'hostingPlan-${timestamp}'
  scope: resourceGroup(resourceGroupNamePlan)
  params: {
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    name: hostingPlanName
    hostingPlanPricing: hostingPlanPricing
    tags: tags
    zoneRedundant: hostingPlanZoneRedundant
  }
  dependsOn: [
    rgs
  ]
}

resource existingPlan 'Microsoft.Web/serverfarms@2023-01-01' existing = if(hostingPlanType == 'Standard' && !deployHostingPlan && !empty(hostingPlanId)) {
  name: last(split(hostingPlanId, '/'))
  scope: resourceGroup(split(hostingPlanId, '/')[2], split(hostingPlanId, '/')[4])
}

module storageResources 'modules/storage.bicep' = {
  name: 'storage-resources-${timestamp}'
  scope: resourceGroup(resourceGroupNameStorage)
  params: {
    location: location
    deployStorageAccount: deployStorageAccount
    enableStoragePrivateEndpoints: enableStoragePrivateEndpoints
    fileShareName: toLower(logicAppName)
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    nameConvPrivEndpoints: nameConvPrivEndpoints
    storageAccountId: storageAccountId
    storageAccountName: storageAccountName
    storageAccountPrivateEndpointSubnetId: enableStoragePrivateEndpoints ? ( !empty(storagePrivateEndpointSubnetId) ? storagePrivateEndpointSubnetId : networking.outputs.subnetIds[1] ) : ''
    storageAccountSku: storageAccountSku 
    storageBlobDnsZoneId: enableStoragePrivateEndpoints ? ( !empty(storageBlobDnsZoneId) ? storageBlobDnsZoneId : networking.outputs.privateDnsZoneIds[0] ) : ''
    storageFileDnsZoneId: enableStoragePrivateEndpoints ? ( !empty(storageFileDnsZoneId) ? storageFileDnsZoneId : networking.outputs.privateDnsZoneIds[1] ) : ''
    storageQueueDnsZoneId: enableStoragePrivateEndpoints ? ( !empty(storageQueueDnsZoneId) ? storageQueueDnsZoneId : networking.outputs.privateDnsZoneIds[2] ) : ''
    storageTableDnsZoneId: enableStoragePrivateEndpoints ? ( !empty(storageTableDnsZoneId) ? storageTableDnsZoneId : networking.outputs.privateDnsZoneIds[3] ) : ''
    tags: tags
  }
}

module logicAppResources 'modules/logicApp.bicep' = {
  name: 'logicApp-resources-${timestamp}'
  scope: resourceGroup(resourceGroupNameLogicApp)
  params: {
    enableApplicationInsights: enableApplicationInsights
    enableInboundPrivateEndpoint: enableInboundPrivateEndpoint
    enablePublicAccess: enablePublicAccess
    hostingPlanId: !empty(hostingPlanId) ? hostingPlanId : ( deployHostingPlan ? hostingPlan.outputs.hostingPlanId : '' )
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    logicAppInboundSubnetId: enableInboundPrivateEndpoint ? ( !empty(logicAppInboundSubnetId) ? logicAppInboundSubnetId : networking.outputs.subnetIds[2] ) : ''
    logicAppName: logicAppName
    logicAppOutboundSubnetId: enableVnetIntegration ? ( !empty(logicAppOutboundSubnetId) ? logicAppOutboundSubnetId : networking.outputs.subnetIds[0] ) : ''
    logicAppPrivateDnsZoneId: enableInboundPrivateEndpoint ? ( !empty(logicAppPrivateDnsZoneId) ? logicAppPrivateDnsZoneId : networking.outputs.privateDnsZoneIds[4] ) : ''
    nameConvPrivEndpoints: nameConvPrivEndpoints
    storageAccountResourceId: storageResources.outputs.storageAccountResourceId 
    tags: tags
  }
  dependsOn: [
    rgs
    hostingPlan
    networking
  ]
}
