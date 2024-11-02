// Basics
targetScope = 'subscription'

@description('The location of all resources deployed by this template.')
param location string

@description('Optional. Reverse the order of the resource type and name in the generated resource name. Default is false.')
param nameConvResTypeAtEnd bool = false

@description('Required. The name of the function App.')
param functionAppName string

@description('Required. The name of the resource group where the function App will be deployed.')
param functionAppResourceGroupName string

@description('Optional. The type of site to deploy')
@allowed([
  'functionapp'       // function app windows os
  'functionapp,linux' // function app linux os
])
param functionAppKind string = 'functionapp,linux'

@description('Optional. The runtime stack used by the function App.')
@allowed([
  'dotnet'
  'java'
  'node'
  'powershell'
  'python'
])
param runtimeStack string = 'dotnet'

@description('Optional. The version of the runtime stack used by the function App. The version must be compatible with the runtime stack.')
param runtimeVersion string = '.NET 8 Isolated'

@description('Optional. Determines the memory size of the instances on which your app runs in the FlexConsumption hosting plan.')
@allowed([
  2048
  4096
])
param flexConsumptionInstanceMemoryMB int = 2048

@description('Optional. The maximum number of instances that the function App can scale out to in the FlexConsumption hosting plan.')
@minValue(40)
@maxValue(1000)
param flexConsumptionMaximumInstanceCount int = 100

// Hosting Plan

@description('Required. Determines whether or not a new host plan is deployed. If set to false and the host plan type is not "Consumption", then the "hostingPlanId" parameter must be provided.')
param deployHostingPlan bool

@description('''Conditional. When you create a function app in Azure, you must choose a hosting plan for your app.
There are three basic Azure Functions hosting plans provided by Azure Functions: Consumption plan, Premium plan, and Dedicated (App Service) plan. 
* Consumption: Scale automatically and only pay for compute resources when your functions are running.
* FlexConsumption: Flex Consumption is a Linux-based Azure Functions hosting plan that builds on the Consumption pay for what you use serverless billing model. It gives you more flexibility and customizability by introducing private networking, instance memory size selection, and fast/large scale-out features still based on a serverless model.
* FunctionsPremium: Automatically scales based on demand using pre-warmed workers, which run applications with no delay after being idle, runs on more powerful instances, and connects to virtual networks.
* AppServicePlan: Best for long-running scenarios where Durable Functions can't be used. Consider an App Service plan in the following situations:
  * You have existing, underutilized VMs that are already running other App Service instances.
  * Predictive scaling and costs are required.
''')
@allowed([
  'Consumption'
  'FlexConsumption' // Preview - limited regional availability
  'FunctionsPremium'
  'AppServicePlan'
  ''
])
param hostingPlanType string = ''

@description('Conditional. The resource Id of the existing server farm to use for the function App.')
param hostingPlanId string = ''

@description('Conditional. The name of the service plan used by the function App. Not used when "hostingPlanId" is provided or hostingPlanType is set to "Consumption".')
param hostingPlanName string = ''

@description('Conditional. The name of the resource Group where the hosting plan will be deployed. Not used when "hostingPlanId" is provided or hostingPlanType is set to "Consumption".')
param hostingPlanResourceGroupName string = ''

@description('Optional. The hosting plan pricing plan. Not used when "hostingPlanId" is provided or hostingPlanType is set to "Consumption".')
@allowed([
  'ElasticPremium_EP1'
  'ElasticPremium_EP2'
  'ElasticPremium_EP3'
  'FlexConsumption_FC1' // Preview - limited regional availability
  'Basic_B1'
  'Standard_S1'
  'PremiumV3_P1V3'
  'PremiumV3_P2V3'
  'PremiumV3_P3V3'
  ''
])
param hostingPlanPricing string = ''

@description('Optional. Determines if the hosting plan is zone redundant. Not used when "hostingPlanId" is provided or hostingPlanType is set to "Consumption".')
param hostingPlanZoneRedundant bool = false

@description('Optional. Determines whether an existing storage account is used or a new one is deployed. If set to true, the "storageAccountName" parameter must be provided. If set to false, the "storageAccountId" parameter must be provided.')
param deployStorageAccount bool = true

@description('Conditional. The resource Id of the existing storage account to be used with the logic app.')
param storageAccountId string = ''

@description('Conditional. The name of the storage account used by the function App. Required if "deployStorageAccount" is set to true.')
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
param functionAppInboundSubnetId string = ''

@description('Conditional. The resource Id of the subnet used by the function App for outbound traffic. Required when "enableVnetIntegration" is set to true and you aren\'t creating a new vnet and subnets.')
param functionAppOutboundSubnetId string = ''

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
param functionAppOutboundSubnetName string = 'fa-outbound-subnet'

@description('Optional. The address prefix of the subnet used by the function App for Virtual Network Integration. Used when "enableVnetIntegration" is set to true and "deployNetworking" = true.')
param functionAppOutboundSubnetAddressPrefix string = '10.0.0.0/24'

@description('Optional. Determines whether private endpoints are used on the function app storage account. Used when "enableVnetIntegration" is set to true.')
param enableStoragePrivateEndpoints bool = true

@description('Optional. The name of the subnet used for private Endpoints. Used when "enableVnetIntegration", "enableStoragePrivateEndpoints", and "deployNetworking" are all set to  "true".')
param storagePrivateEndpointSubnetName string = 'storage-subnet'

@description('Optional. The address prefix of the subnet used for private Endpoints. Used when "enableVnetIntegration", "enableStoragePrivateEndpoints", and "deployNetworking" are all set to  "true".')
param storagePrivateEndpointSubnetAddressPrefix string = '10.0.1.0/24'

//  only required when enableInboundPrivateEndpoint is set to false
@description('Optional. The name of the subnet used by the function App for inbound access when public access is disabled. Used when "enableInboundPrivateEndpoint" and "deployNetworking" = true.')
param functionAppInboundSubnetName string = 'fa-inbound-subnet'

@description('Optional. The address prefix of the subnet used by the function App for inbound access when public access is disabled. Used when "enableInboundPrivateEndpoint" and "deployNetworking" = true.')
param functionAppInboundSubnetAddressPrefix string = '10.0.2.0/24'

// Private DNS Zones

@description('Conditional. The resource Id of the function app private DNS Zone. Required when "enableInboundPrivateEndpoint" = true and "deployNetworking" = false.')
param functionAppPrivateDnsZoneId string = ''

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

// existing resources

resource existingHostingPlan 'Microsoft.Web/serverfarms@2023-01-01' existing = if(!empty(hostingPlanId)) {
  name: last(split(hostingPlanId, '/'))
  scope: resourceGroup(split(hostingPlanId, '/')[2], split(hostingPlanId, '/')[4])
}

// variables

var cloudSuffix = replace(replace(environment().resourceManager, 'https://management.', ''), '/', '')
var privateDnsZoneSuffixes_AzureWebSites = {
  AzureCloud: 'azurewebsites.net'
  AzureUSGovernment: 'azurewebsites.us'
  USNat: null
  USSec: null
}
var webSitePrivateDnsZoneName = enableInboundPrivateEndpoint ? [
  'privatelink.${privateDnsZoneSuffixes_AzureWebSites[environment().name] ?? 'appservice.${cloudSuffix}'}'
] : []

var existingHostingPlanType = !empty(existingHostingPlan) ? ( contains(existingHostingPlan.sku.tier, 'Flex') ? 'FlexConsumption' : (contains(existingHostingPlan.sku.tier, 'Elastic') ? 'FunctionsPremium' : 'AppServicePlan' ) ) : ''
var blobContainerName = 'app-package-${toLower(functionAppName)}'
var locations = (loadJsonContent('../../data/locations.json'))[environment().name]
var resourceAbbreviations = loadJsonContent('../../data/resourceAbbreviations.json')

var nameConvPrivEndpoints = nameConvResTypeAtEnd ? 'resourceName-service-${locations[location].abbreviation}-${resourceAbbreviations.privateEndpoints}-uniqueString' : '${resourceAbbreviations.privateEndpoints}-resourceName-service-${locations[location].abbreviation}-uniqueString'
var storageAccountSku = deployHostingPlan ? ( hostingPlanZoneRedundant ? 'Standard_ZRS' : 'Standard_LRS' ) : ( existingHostingPlan.properties.numberOfWorkers > 1 ? 'Standard_ZRS' : 'Standard_LRS' )

var subnetOutbound = enableVnetIntegration ? [
  {
    name: functionAppOutboundSubnetName
    properties: {
      delegations: [
        {
          name: hostingPlanType == 'FlexConsumption' ? 'appEnvironments' : 'webServerFarms'
          properties: {
            serviceName: hostingPlanType == 'FlexConsumption' ? 'Microsoft.App/environments' : 'Microsoft.Web/serverFarms'
          }
        }
      ]
      addressPrefix: functionAppOutboundSubnetAddressPrefix
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
    name: functionAppInboundSubnetName
    properties: {
      privateEndpointNetworkPolicies: 'Disabled'
      addressPrefix: functionAppInboundSubnetAddressPrefix
    }
  }
] : []

var storagePrivateDnsZoneNames =  enableStoragePrivateEndpoints ? [
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.file.${environment().suffixes.storage}'
  'privatelink.queue.${environment().suffixes.storage}'
  'privatelink.table.${environment().suffixes.storage}'
] : []

// ensure that no resource Group Names are blank for deployments
var resourceGroupNameFunctionApp = functionAppResourceGroupName
var resourceGroupNameStorage = !empty(storageAccountId) && !deployStorageAccount ? split(storageAccountId, '/')[4] : resourceGroupNameFunctionApp
var resourceGroupNameHostingPlan = !empty(hostingPlanResourceGroupName) ? hostingPlanResourceGroupName : resourceGroupNameFunctionApp
var resourceGroupNameNetworking = !empty(networkingResourceGroupName) ? networkingResourceGroupName : resourceGroupNameFunctionApp

var resourceGroupNames = [
  resourceGroupNameNetworking
  resourceGroupNameHostingPlan
  resourceGroupNameFunctionApp  
]

// deployments

resource rgs 'Microsoft.Resources/resourceGroups@2023-07-01' = [for resourceGroupName in union(resourceGroupNames, resourceGroupNames): {
  name: resourceGroupName
  location: location
}]

module networking 'modules/networking.bicep' = if(deployNetworking && (enableVnetIntegration || enableInboundPrivateEndpoint)) {
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

module hostingPlan 'modules/hostingPlan.bicep' = if(deployHostingPlan) {
  name: 'hostingPlan-${timestamp}'
  scope: resourceGroup(resourceGroupNameHostingPlan)
  params: {
    functionAppKind: functionAppKind
    hostingPlanType: hostingPlanType!
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    name: hostingPlanName
    planPricing: hostingPlanPricing!
    tags: tags
    zoneRedundant: hostingPlanZoneRedundant
  }
  dependsOn: [
    rgs
  ]
}

module storageResources 'modules/storage.bicep' = {
  name: 'storage-resources-${timestamp}'
  scope: resourceGroup(resourceGroupNameStorage)
  params: {
    location: location
    containerName: blobContainerName
    deployStorageAccount: deployStorageAccount
    enableStoragePrivateEndpoints: enableStoragePrivateEndpoints
    fileShareName: deployHostingPlan ? ( hostingPlanType != 'AppServicePlan' ? toLower(functionAppName) : '' ) : ( existingHostingPlanType != 'AppServicePlan' ? toLower(functionAppName) : '' )
    hostPlanType: deployHostingPlan ? hostingPlanType : existingHostingPlanType
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

module functionAppResources 'modules/functionApp.bicep' = {
  name: 'functionApp-resources-${timestamp}'
  scope: resourceGroup(functionAppResourceGroupName)
  params: {
    location: location
    blobContainerName: blobContainerName
    enableApplicationInsights: enableApplicationInsights
    enablePublicAccess: enablePublicAccess
    enableInboundPrivateEndpoint: enableInboundPrivateEndpoint
    functionAppKind: functionAppKind
    functionAppName: functionAppName
    functionAppOutboundSubnetId: enableVnetIntegration ? ( !empty(functionAppOutboundSubnetId) ? functionAppOutboundSubnetId : networking.outputs.subnetIds[0] ) : ''
    functionAppInboundSubnetId: enableInboundPrivateEndpoint ? ( !empty(functionAppInboundSubnetId) ? functionAppInboundSubnetId : networking.outputs.subnetIds[2] ) : ''    
    functionAppPrivateDnsZoneId: enableInboundPrivateEndpoint ? ( !empty(functionAppPrivateDnsZoneId) ? functionAppPrivateDnsZoneId : networking.outputs.privateDnsZoneIds[4] ) : ''
    hostingPlanType: hostingPlanType == 'Consumption' ? '' : ( deployHostingPlan ? hostingPlanType : existingHostingPlanType )
    hostingPlanId: hostingPlanType == 'Consumption' ? '' : ( !empty(hostingPlanId) ? hostingPlanId : ( deployHostingPlan ? hostingPlan.outputs.hostingPlanId : '' ))
    nameConvPrivEndpoints: nameConvPrivEndpoints
    runtimeStack: runtimeStack
    runtimeVersion: runtimeVersion
    storageAccountResourceId: storageResources.outputs.storageAccountResourceId   
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    tags: tags
    instanceMemoryMB: flexConsumptionInstanceMemoryMB
    maximumInstanceCount: flexConsumptionMaximumInstanceCount
  }
  dependsOn: [
    rgs
    hostingPlan
    networking
  ]
}
