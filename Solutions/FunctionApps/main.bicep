// Basics
targetScope = 'subscription'

@description('The location of all resources deployed by this template.')
param location string

@description('Optional. Reverse the order of the resource type and name in the generated resource name. Default is false.')
param nameConvResTypeAtEnd bool = false

@description('Required. The name of the function App.')
param functionAppName string

@description('''Required. An object containing the name of the resource group where the function App will be deployed and whether it is an existing or New resource group.
{
  name: string
  mode: New | Existing
}
''')
param functionAppResourceGroup object

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

@description('Required. Determines whether or not a new host plan is deployed. If set to false then the "hostingPlanId" parameter must be provided.')
param deployHostingPlan bool

@description('''Conditional. When you create a function app in Azure, you must choose a hosting plan for your app.
There are four basic Azure Functions hosting plans provided by Azure Functions: Consumption plan, Flex Consumption, Premium plan, and Dedicated (App Service) plan. 
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
])
param hostingPlanType string = 'Consumption'

@description('Conditional. The resource Id of the existing server farm to use for the function App. Required when "deployHostingPlan" is set to false.')
param hostingPlanId string = ''

@description('Conditional. The name of the service plan used by the function App. Required when "deployHostingPlan" is set to true.')
param hostingPlanName string = ''

@description('''Conditional. And object containing the name of the resource Group and creation mode for the hosting plan. Required when "deployHostingPlan" is set to true.
{
  name: string
  mode: New | Existing
}
''')
param hostingPlanResourceGroup object = {}

@description('Conditional. The hosting plan pricing plan. Required when "deployHostingPlan" is set to true and hostingPlanType is not set to "Consumption".')
@allowed([
  'Dynamic_Y1' // Consumption Plan
  'ElasticPremium_EP1' // Elastic Premium
  'ElasticPremium_EP2' // Elastic Premium
  'ElasticPremium_EP3' // Elastic Premium
  'FlexConsumption_FC1' // Preview - limited regional availability
  'Free_F1' // App Service Plan
  'Basic_B1' // App Service Plan
  'Basic_B2' // App Service Plan
  'Basic_B3' // App Service Plan
  'PremiumV3_P0V3' // App Service Plan
  'PremiumV3_P1V3' // App Service Plan
  'PremiumV3_P1mv3' // App Service Plan, Linux Only
  'PremiumV3_P2V3' // App Service Plan
  'PremiumV3_P2mv3' // App Service Plan, Linux Only
  'PremiumV3_P3V3' // App Service Plan
  'PremiumV3_P3mv3' // App Service Plan, Linux Only
  'PremiumV3_P4mv3' // App Service Plan, Linux Only
  'PremiumV3_P5mv3' // App Service Plan, Linux Only
  'Shared_D1' // App Service Plan, Windows Only
])
param hostingPlanPricing string = 'Dynamic_Y1'

@description('Optional. Determines if the hosting plan is zone redundant. Not used when "hostingPlanId" is provided or hostingPlanType is set to "Consumption".')
param hostingPlanZoneRedundant bool = false

// Storage Account
@description('Optional. Determines whether an existing storage account is used or a new one is deployed. If set to true, the "storageAccountName" parameter must be provided. If set to false, the "storageAccountId" parameter must be provided.')
param deployStorageAccount bool = true

@description('Conditional. The resource Id of the existing storage account to be used with the logic app. Required when "deployStorageAccount" is set to false.')
param storageAccountId string = ''

@description('Conditional. The name of the storage account used by the function App. Required if "deployStorageAccount" is set to true.')
param storageAccountName string = ''

@description('Optional. For Function Apps using the Consumption or FunctionsPremium hosting plans, determines whether the function App should be connected to the storage account through an Azure Files share.')
param addAzureFilesConnection bool = false

// Monitoring

@description('Optional. Enable Application Insights for the function App.')
param enableApplicationInsights bool = true

@description('Optional. Associate the applications insights with an Azure Monitor Private Link Scope. Used only when enableApplicationInsights is set to true.')
param privateLinkScopeResourceId string = ''

@description('Optional. To enable diagnostics settings, provide the resource Id of the Log Analytics workspace where logs are to be sent.')
param logAnalyticsWorkspaceId string = ''

// Networking

@description('Optional. Indicates whether the function App should be accessible from the public network.')
param enablePublicAccess bool = false

@description('Optional. The network rules that are applied to inbound access for the function App.')
param ipSecurityRestrictions array = []

@description('Optional. Indicates what the default action is when an IP restriction rule is not matched.')
@allowed([
  'Allow'
  'Deny'
])
param ipSecurityRestrictionsDefaultAction string = 'Deny'

@description('Optional. The network rules that are applied to inbound access for the advanced (scm) website of the function app.')
param scmIpSecurityRestrictions array = []

@description('Optional. Indicates what the default action is when an IP restriction rule is not matched.')
@allowed([
  'Allow'
  'Deny'
])
param scmIpSecurityRestrictionsDefaultAction string = 'Allow'

@description('Optional. Determines whether the IP security restrictions for the scm site are the same as the main site.')
param scmIpSecurityRestrictionsUseMain bool = true

@description('Optional. Indicates whether the function App should be accessible via a private endpoint.')
param enableInboundPrivateEndpoint bool = false

@description('Optional. Indicates whether outbound traffic from the function App should be routed over a vnet.')
param enableVnetIntegration bool = true

@description('Optional. Indicates whether a new Vnet and associated resources should be deployed to support the hosting plan and function app.')
param deployNetworking bool = false

@description('Optional. Indicates whether private DNS zones should be created for the function App.')
param deployFunctionAppPrivateDnsZone bool = false

@description('Optional. Indicates whether private DNS zones should be created for the storage account.')
param deployStoragePrivateDnsZones bool = false

//  existing Subnets

@description('Conditional. The resource Id of the subnet used by the function App for inbound traffic. Required when "enableInboundPrivateEndpoint" is set to true and "deployNetworking" is set to false.')
param functionAppInboundSubnetId string = ''

@description('Conditional. The resource Id of the subnet used by the function App for outbound traffic. Required when "enableVnetIntegration" is set to true and "deployNetworking" is set to false.')
param functionAppOutboundSubnetId string = ''

@description('Conditional The resource Id of the private Endpoint Subnet. Required when "enableStoragePrivateEndpoints" is set to true and "deployNetworking" is set to false.')
param storagePrivateEndpointSubnetId string = ''

//  new Virtual Network (only used when the existing subnets aren't specified. Fill in all values where needed.)

@description('Conditional. The name of the virtual network used for Virtual Network Integration. Required when "enableVnetIntegration" is set to true and "deployNetworking" = true.')
param vnetName string = ''

@description('''Conditional. An object containing the name and mode of creation of the resource group where the virtual network is deployed. Required when "enableVnetIntegration" is set to true and "deployNetworking" = true.
{
  name: string
  mode: New | Existing
}
''')
param networkingResourceGroup object = {}

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

@description('Optional. The resource Id of the function app private DNS Zone. Required when "enableInboundPrivateEndpoint" = true and "deployNetworking" = false.')
param functionAppPrivateDnsZoneId string = ''

@description('Optional. The resource Id of the blob storage Private DNS Zone. Required when "enableVnetIntegration" and "enableStoragePrivateEndpoints" = true and "deployNetworking = false.')
param storageBlobDnsZoneId string = ''

@description('Optional. The resource Id of the file storage Private DNS Zone. Required when "enableVnetIntegration" and "enableStoragePrivateEndpoints" = true and "deployNetworking = false.')
param storageFileDnsZoneId string = ''

@description('Optional. The resource Id of the queue storage Private DNS Zone. Required when "enableVnetIntegration" and "enableStoragePrivateEndpoints" = true and "deployNetworking = false.')
param storageQueueDnsZoneId string = ''

@description('Optional. The resource Id of the table storage Private DNS Zone. Required when "enableVnetIntegration" and "enableStoragePrivateEndpoints" = true and "deployNetworking = false.')
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

// existing resources

resource existingHostingPlan 'Microsoft.Web/serverfarms@2023-01-01' existing = if(!empty(hostingPlanId)) {
  name: last(split(hostingPlanId, '/'))
  scope: resourceGroup(split(hostingPlanId, '/')[2], split(hostingPlanId, '/')[4])
}

// variables
var cloudSuffix = replace(replace(environment().resourceManager, 'https://management.', ''), '/', '')
var deployResourceGroupNames = [
  !empty(functionAppResourceGroup) && functionAppResourceGroup.mode == 'New' ? functionAppResourceGroup.name : ''
  !empty(hostingPlanResourceGroup) && hostingPlanResourceGroup.mode == 'New' ? hostingPlanResourceGroup.name : ''
  !empty(networkingResourceGroup) && networkingResourceGroup.mode == 'New' ? networkingResourceGroup.name : ''
]

var deploymentSuffix = uniqueString(deployment().name, location)

var privateDnsZoneSuffixes_AzureWebSites = {
  AzureCloud: 'azurewebsites.net'
  AzureUSGovernment: 'azurewebsites.us'
  USNat: null
  USSec: null
}
var webSitePrivateDnsZoneName = enableInboundPrivateEndpoint ? [
  'privatelink.${privateDnsZoneSuffixes_AzureWebSites[environment().name] ?? 'appservice.${cloudSuffix}'}'
] : []

var existingHostingPlanType = !empty(existingHostingPlan) ? ( contains(existingHostingPlan.sku.tier, 'Flex') ? 'FlexConsumption' : ( contains(existingHostingPlan.sku.tier, 'Elastic') ? 'FunctionsPremium' : ( existingHostingPlan.sku.tier == 'Dynamic' ? 'Consumption' : 'AppServicePlan' ) ) ) : ''
var blobContainerName =  ( deployHostingPlan && ( hostingPlanType == 'FlexConsumption' || ( hostingPlanType != 'AppServicePlan' && !addAzureFilesConnection ) ) ) || ( !deployHostingPlan && ( existingHostingPlanType == 'FlexConsumption' || ( existingHostingPlan != 'AppServicePlan' && !addAzureFilesConnection ) ) ) ? 'app-package-${toLower(functionAppName)}' : ''
var fileShareName = (deployHostingPlan && (hostingPlanType == 'Consumption' || hostingPlanType == 'FunctionsPremium')) || (!deployHostingPlan && (existingHostingPlanType == 'Consumption' || existingHostingPlanType == 'FunctionsPremium')) ? ( addAzureFilesConnection ? toLower(functionAppName) : '' ) : ''

//var locations = (loadJsonContent('../../data/locations.json'))[environment().name]
var resourceAbbreviations = loadJsonContent('../../data/resourceAbbreviations.json')

var privateEndpointNameConv = replace(
  nameConvResTypeAtEnd ? 'RESOURCENAME-SERVICE-VNET-RESOURCETYPE' : 'RESOURCETYPE-RESOURCENAME-SERVICE-VNET',
  'RESOURCETYPE',
  resourceAbbreviations.privateEndpoints
)
var privateEndpointNICNameConvTemp = nameConvResTypeAtEnd
  ? '${privateEndpointNameConv}-RESOURCETYPE'
  : 'RESOURCETYPE-${privateEndpointNameConv}'
var privateEndpointNICNameConv = replace(
  privateEndpointNICNameConvTemp,
  'RESOURCETYPE',
  resourceAbbreviations.networkInterfaces
)

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

var resourceGroupNameStorage = !empty(storageAccountId) && !deployStorageAccount ? split(storageAccountId, '/')[4] : functionAppResourceGroup.name
var resourceGroupNameHostingPlan = !empty(hostingPlanResourceGroup) ? hostingPlanResourceGroup.name : functionAppResourceGroup.name
var resourceGroupNameNetworking = !empty(networkingResourceGroup) ? networkingResourceGroup.name : functionAppResourceGroup.name

// deployments

resource rgs 'Microsoft.Resources/resourceGroups@2023-07-01' = [for rgName in deployResourceGroupNames: if(!empty(rgName)) {
  name: rgName
  location: location
}]

module networking 'modules/networking.bicep' = if(deployNetworking && (deployStoragePrivateDnsZones || deployFunctionAppPrivateDnsZone || enableVnetIntegration || enableInboundPrivateEndpoint)) {
  name: 'networking-resources-${deploymentSuffix}'
  scope: resourceGroup(resourceGroupNameNetworking)
  params: {
    deploymentSuffix: deploymentSuffix
    location: location
    privateDnsZoneNames: deployStoragePrivateDnsZones ? ( deployFunctionAppPrivateDnsZone ? union(storagePrivateDnsZoneNames, webSitePrivateDnsZoneName) : storagePrivateDnsZoneNames ) : ( deployFunctionAppPrivateDnsZone ? webSitePrivateDnsZoneName : [] )
    subnets: union(subnetOutbound, subnetStoragePrivateEndpoints, subnetInboundPrivateEndpoint)
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    tags: tags
  }
  dependsOn: [
    rgs
  ]
}

module hostingPlan 'modules/hostingPlan.bicep' = if(deployHostingPlan) {
  name: 'hostingPlan-${deploymentSuffix}'
  scope: resourceGroup(resourceGroupNameHostingPlan)
  params: {
    functionAppKind: functionAppKind
    hostingPlanType: hostingPlanType
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    name: hostingPlanName
    planPricing: hostingPlanPricing
    tags: tags
    zoneRedundant: hostingPlanZoneRedundant
  }
  dependsOn: [
    rgs
  ]
}

module storageResources 'modules/storage.bicep' = {
  name: 'storage-resources-${deploymentSuffix}'
  scope: resourceGroup(resourceGroupNameStorage)
  params: {
    location: location
    containerName: blobContainerName
    deployStorageAccount: deployStorageAccount
    enableStoragePrivateEndpoints: enableStoragePrivateEndpoints
    fileShareName: fileShareName
    hostPlanType: deployHostingPlan ? hostingPlanType : existingHostingPlanType
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    privateEndpointNameConv: privateEndpointNameConv
    privateEndpointNICNameConv: privateEndpointNICNameConv
    storageAccountId: storageAccountId
    storageAccountName: storageAccountName
    storageAccountPrivateEndpointSubnetId: enableStoragePrivateEndpoints ? ( deployNetworking && (enableVnetIntegration || enableInboundPrivateEndpoint) ? networking.outputs.subnetIds[1] : storagePrivateEndpointSubnetId  ) : ''
    storageAccountSku: storageAccountSku 
    storageBlobDnsZoneId: enableStoragePrivateEndpoints ? ( deployNetworking && deployStoragePrivateDnsZones ? first(filter(networking.outputs.privateDnsZoneIds, zone => contains(zone, '.blob.'))) : storageBlobDnsZoneId ) : ''
    storageFileDnsZoneId: enableStoragePrivateEndpoints ? ( deployNetworking && deployStoragePrivateDnsZones ? first(filter(networking.outputs.privateDnsZoneIds, zone => contains(zone, '.file.'))) : storageFileDnsZoneId ) : ''
    storageQueueDnsZoneId: enableStoragePrivateEndpoints ? ( deployNetworking && deployStoragePrivateDnsZones ? first(filter(networking.outputs.privateDnsZoneIds, zone => contains(zone, '.queue.'))) : storageQueueDnsZoneId ) : ''
    storageTableDnsZoneId: enableStoragePrivateEndpoints ? ( deployNetworking && deployStoragePrivateDnsZones ? first(filter(networking.outputs.privateDnsZoneIds, zone => contains(zone, '.table.'))) : storageTableDnsZoneId ) : ''
    tags: tags
  }
}

module functionAppResources 'modules/functionApp.bicep' = {
  name: 'functionApp-resources-${deploymentSuffix}'
  scope: resourceGroup(functionAppResourceGroup.name)
  params: {
    location: location
    blobContainerName: blobContainerName
    deploymentSuffix: deploymentSuffix
    enableApplicationInsights: enableApplicationInsights
    enablePublicAccess: enablePublicAccess
    enableInboundPrivateEndpoint: enableInboundPrivateEndpoint
    fileShareName: fileShareName
    functionAppKind: functionAppKind
    functionAppName: functionAppName
    functionAppOutboundSubnetId: enableVnetIntegration ? ( deployNetworking ? networking.outputs.subnetIds[0] : functionAppOutboundSubnetId ) : ''
    functionAppInboundSubnetId: enableInboundPrivateEndpoint ? ( deployNetworking ? networking.outputs.subnetIds[2] : functionAppInboundSubnetId ) : ''    
    functionAppPrivateDnsZoneId: enableInboundPrivateEndpoint ? ( deployNetworking && deployFunctionAppPrivateDnsZone ? first(filter(networking.outputs.privateDnsZoneIds, zone => contains(zone, webSitePrivateDnsZoneName))) : functionAppPrivateDnsZoneId ) : ''
    hostingPlanType: deployHostingPlan ? hostingPlanType : existingHostingPlanType
    hostingPlanId: deployHostingPlan ? hostingPlan.outputs.hostingPlanId : hostingPlanId
    ipSecurityRestrictions: ipSecurityRestrictions
    ipSecurityRestrictionsDefaultAction: ipSecurityRestrictionsDefaultAction
    scmIpSecurityRestrictions: scmIpSecurityRestrictions
    scmIpSecurityRestrictionsDefaultAction: scmIpSecurityRestrictionsDefaultAction
    scmIpSecurityRestrictionsUseMain: scmIpSecurityRestrictionsUseMain
    privateEndpointNameConv: privateEndpointNameConv
    privateEndpointNICNameConv: privateEndpointNICNameConv
    privateLinkScopeResourceId: privateLinkScopeResourceId
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
  ]
}
