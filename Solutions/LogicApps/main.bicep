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

@description('Required. Determines whether or not a new host plan is deployed. If set to false and the host plan type is not "Consumption", then the "planId" parameter must be provided.')
param deployPlan bool

@description('''Optional. When you create a logic app in Azure, you must choose a hosting plan for your app.
There are two basic hosting plans provided by Azure for logic apps: Consumption or Standard plans. 
* Consumption: Best for entry-level. Pay only as much as your workflow runs.
* Standard: Best for enterprise-level, serverless applications, with event-based scaling and networking isolation.
''')
@allowed([
  'Consumption'
  'Standard'
])
param planType string = 'Standard'

@description('Conditional. The resource Id of the existing server farm to use for the function App.')
param planId string = ''

@description('Conditional. The name of the service plan used by the function App. Not used when "planId" is provided or planType is set to "Consumption".')
param planName string = ''

@description('Conditional. The name of the resource Group where the hosting plan will be deployed. Not used when "planId" is provided or planType is set to "Consumption".')
param planResourceGroupName string = ''

@description('Optional. The hosting plan pricing plan. Not used when "planId" is provided or planType is set to "Consumption".')
@allowed([
  'WorkflowStandard_WS1'
  'WorkflowStandard_WS2'
  'WorkflowStandard_WS3'
])
param planPricing string = 'WorkflowStandard_WS1'

@description('Optional. Determines if the hosting plan is zone redundant. Not used when "planId" is provided or planType is set to "Consumption".')
param planZoneRedundant bool = false

@description('Required. The name of the storage account used by the function App.')
param storageAccountName string

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

var nameConvPrivEndpoints = nameConvResTypeAtEnd ? 'resourceName-service-${locations[location].abbreviation}-${resourceAbbreviations.privateEndpoints}' : '${resourceAbbreviations.privateEndpoints}-resourceName-service-${locations[location].abbreviation}'

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
var resourceGroupNamePlan = !empty(planResourceGroupName) ? planResourceGroupName : resourceGroupNameLogicApp
var resourceGroupNameNetworking = !empty(networkingResourceGroupName) ? networkingResourceGroupName : resourceGroupNameLogicApp

var resourceGroupNames = [
  resourceGroupNameNetworking
  resourceGroupNamePlan
  resourceGroupNameLogicApp  
]

resource rgs 'Microsoft.Resources/resourceGroups@2023-07-01' = [for resourceGroupName in union(resourceGroupNames, resourceGroupNames): {
  name: resourceGroupName
  location: location
}]

module workflow 'modules/workflow.bicep' = if(planType == 'Consumption') {
  name: 'workflow-${timestamp}'
  scope: resourceGroup(resourceGroupNameLogicApp)
  params: {
    workflowName: logicAppName
    location: location
    zoneRedundancy: planZoneRedundant ? 'Enabled' : ''
    tags: tags
  }
  dependsOn: [
    rgs
  ]
}

module networking 'modules/networking.bicep' = if(planType == 'Standard' && deployNetworking && (enableVnetIntegration || enableInboundPrivateEndpoint)) {
  name: 'networking-${timestamp}'
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

module plan 'modules/hostingPlan.bicep' = if(planType == 'Standard' && deployPlan) {
  name: 'plan-${timestamp}'
  scope: resourceGroup(resourceGroupNamePlan)
  params: {
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    name: planName
    planPricing: planPricing
    tags: tags
    zoneRedundant: planZoneRedundant
  }
  dependsOn: [
    rgs
  ]
}

module logicAppResources 'modules/logicAppResources.bicep' = if(planType == 'Standard') {
  name: 'logicAppResources-${timestamp}'
  scope: resourceGroup(logicAppResourceGroupName)
  params: {
    location: location
    enableApplicationInsights: enableApplicationInsights
    enablePublicAccess: enablePublicAccess
    enableInboundPrivateEndpoint: enableInboundPrivateEndpoint
    enableStoragePrivateEndpoints: enableStoragePrivateEndpoints
    logicAppName: logicAppName
    planId:  !empty(planId) ? planId : ( deployPlan ? plan.outputs.hostingPlanId : '' )
    storageAccountName: storageAccountName   
    nameConvPrivEndpoints: nameConvPrivEndpoints
    logicAppOutboundSubnetId: enableVnetIntegration ? ( !empty(logicAppOutboundSubnetId) ? logicAppOutboundSubnetId : networking.outputs.subnetIds[0] ) : ''
    storageAccountPrivateEndpointSubnetId: enableStoragePrivateEndpoints ? ( !empty(storagePrivateEndpointSubnetId) ? storagePrivateEndpointSubnetId : networking.outputs.subnetIds[1] ) : ''
    logicAppInboundSubnetId: enableInboundPrivateEndpoint ? ( !empty(logicAppInboundSubnetId) ? logicAppInboundSubnetId : networking.outputs.subnetIds[2] ) : '' 
    storageBlobDnsZoneId: enableStoragePrivateEndpoints ? ( !empty(storageBlobDnsZoneId) ? storageBlobDnsZoneId : networking.outputs.privateDnsZoneIds[0] ) : ''
    storageFileDnsZoneId: enableStoragePrivateEndpoints ? ( !empty(storageFileDnsZoneId) ? storageFileDnsZoneId : networking.outputs.privateDnsZoneIds[1] ) : ''
    storageQueueDnsZoneId: enableStoragePrivateEndpoints ? ( !empty(storageQueueDnsZoneId) ? storageQueueDnsZoneId : networking.outputs.privateDnsZoneIds[2] ) : ''
    storageTableDnsZoneId: enableStoragePrivateEndpoints ? ( !empty(storageTableDnsZoneId) ? storageTableDnsZoneId : networking.outputs.privateDnsZoneIds[3] ) : ''
    logicAppPrivateDnsZoneId: enableInboundPrivateEndpoint ? ( !empty(logicAppPrivateDnsZoneId) ? logicAppPrivateDnsZoneId : networking.outputs.privateDnsZoneIds[4] ) : ''
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    tags: tags 
  }
  dependsOn: [
    rgs
    plan
    networking
  ]
}
