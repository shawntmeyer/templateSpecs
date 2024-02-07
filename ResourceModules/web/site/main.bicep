metadata name = 'Web/Function Apps'
metadata description = 'This module deploys a Web or Function App.'
metadata owner = 'Azure/module-maintainers'

@description('Required. Name of the site.')
param name string

@description('Optional. Location for all Resources.')
param location string = resourceGroup().location

@description('Required. Type of site to deploy.')
@allowed([
  'functionapp' // function app windows os
  'functionapp,linux' // function app linux os
  'functionapp,workflowapp' // logic app workflow
  'functionapp,workflowapp,linux' // logic app docker container
  'app' // normal web app
])
param kind string

@description('Required. The resource ID of the app service plan to use for the site.')
param serverFarmResourceId string

@description('Optional. Configures a site to accept only HTTPS requests. Issues redirect for HTTP requests.')
param httpsOnly bool = true

@description('Optional. If client affinity is enabled.')
param clientAffinityEnabled bool = true

@description('Optional. The resource ID of the app service environment to use for this resource.')
param appServiceEnvironmentResourceId string = ''

@description('Optional. Enables system assigned managed identity on the resource.')
param systemAssignedIdentity bool = false

@description('Optional. The ID(s) to assign to the resource.')
param userAssignedIdentities object = {}

@description('Optional. The resource ID of the assigned identity to be used to access a key vault with.')
param keyVaultAccessIdentityResourceId string = ''

@description('Optional. Checks if Customer provided storage account is required.')
param storageAccountRequired bool = false

@description('Optional. Azure Resource Manager ID of the Virtual network and subnet to be joined by Regional VNET Integration. This must be of the form /subscriptions/{subscriptionName}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}.')
param virtualNetworkSubnetId string = ''

@description('Optional. To enable accessing content over virtual network.')
param vnetContentShareEnabled bool = false

@description('Optional. To enable pulling image over Virtual Network.')
param vnetImagePullEnabled bool = false

@description('Optional. Virtual Network Route All enabled. This causes all outbound traffic to have Virtual Network Security Groups and User Defined Routes applied.')
param vnetRouteAllEnabled bool = false

@description('Optional. Stop SCM (KUDU) site when the app is stopped.')
param scmSiteAlsoStopped bool = false

@description('Optional. The site config object.')
param siteConfig object = {}

@description('Optional. Required if app of kind functionapp. Resource ID of the storage account to manage triggers and logging function executions.')
param storageAccountResourceId string = ''

@description('Optional. Resource ID of the app insight to leverage for this resource.')
param appInsightResourceId string = ''

@description('Optional. For function apps. If true the app settings "AzureWebJobsDashboard" will be set. If false not. In case you use Application Insights it can make sense to not set it for performance reasons.')
param setAzureWebJobsDashboard bool = contains(kind, 'functionapp') ? true : false

@description('Optional. The app settings-value pairs except for AzureWebJobsStorage, AzureWebJobsDashboard, APPINSIGHTS_INSTRUMENTATIONKEY and APPLICATIONINSIGHTS_CONNECTION_STRING.')
param appSettingsKeyValuePairs object = {}

@description('Optional. The auth settings V2 configuration.')
param authSettingV2Configuration object = {}

@description('Optional. Configuration details for private endpoints. For security reasons, it is recommended to use private endpoints whenever possible.')
param privateEndpoints privateEndpointType

@description('Optional. Configuration for deployment slots for an app.')
param slots array = []

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Resource ID of the diagnostic storage account.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource ID of log analytics workspace.')
param diagnosticWorkspaceId string = ''

@description('Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.')
param diagnosticEventHubName string = ''

@description('Optional. The name of logs that will be streamed. "allLogs" includes all possible logs for the resource. Set to \'\' to disable log collection.')
@allowed([
  ''
  'allLogs'
  'AppServiceHTTPLogs'
  'AppServiceConsoleLogs'
  'AppServiceAppLogs'
  'AppServiceAuditLogs'
  'AppServiceIPSecAuditLogs'
  'AppServicePlatformLogs'
  'FunctionAppLogs'
])
param diagnosticLogCategoriesToEnable array = kind == 'functionapp' ? [
  'FunctionAppLogs'
] : [
  'AppServiceHTTPLogs'
  'AppServiceConsoleLogs'
  'AppServiceAppLogs'
  'AppServiceAuditLogs'
  'AppServiceIPSecAuditLogs'
  'AppServicePlatformLogs'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param diagnosticMetricsToEnable array = [
  'AllMetrics'
]

@description('Optional. The name of the diagnostic setting, if deployed. If left empty, it defaults to "<resourceName>-diagnosticSettings".')
param diagnosticSettingsName string = ''

@description('Optional. To enable client certificate authentication (TLS mutual authentication).')
param clientCertEnabled bool = false

@description('Optional. Client certificate authentication comma-separated exclusion paths.')
param clientCertExclusionPaths string = ''

@description('Optional. This composes with ClientCertEnabled setting.</p>- ClientCertEnabled: false means ClientCert is ignored.</p>- ClientCertEnabled: true and ClientCertMode: Required means ClientCert is required.</p>- ClientCertEnabled: true and ClientCertMode: Optional means ClientCert is optional or accepted.')
@allowed([
  'Optional'
  'OptionalInteractiveUser'
  'Required'
])
param clientCertMode string = 'Optional'

@description('Optional. If specified during app creation, the app is cloned from a source app.')
param cloningInfo object = {}

@description('Optional. Size of the function container.')
param containerSize int = -1

@description('Optional. Unique identifier that verifies the custom domains assigned to the app. Customer will add this ID to a txt record for verification.')
param customDomainVerificationId string = ''

@description('Optional. Maximum allowed daily memory-time quota (applicable on dynamic apps only).')
param dailyMemoryTimeQuota int = -1

@description('Optional. Setting this value to false disables the app (takes the app offline).')
param enabled bool = true

@description('Optional. Hostname SSL states are used to manage the SSL bindings for app\'s hostnames.')
param hostNameSslStates array = []

@description('Optional. Hyper-V sandbox.')
param hyperV bool = false

@description('Optional. Site redundancy mode.')
@allowed([
  'ActiveActive'
  'Failover'
  'GeoRedundant'
  'Manual'
  'None'
])
param redundancyMode string = 'None'

@description('Optional. The site publishing credential policy names which are associated with the sites.')
param basicPublishingCredentialsPolicies array = []

@description('Optional. Names of hybrid connection relays to connect app with.')
param hybridConnectionRelays array = []

@description('Optional. Whether or not public network access is allowed for this resource. For security reasons it should be disabled. If not specified, it will be disabled by default if private endpoints are set.')
@allowed([
  ''
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = ''

var diagnosticsLogsSpecified = [for category in filter(diagnosticLogCategoriesToEnable, item => item != 'allLogs' && item != ''): {
  category: category
  enabled: true
}]

var diagnosticsLogs = contains(diagnosticLogCategoriesToEnable, 'allLogs') ? [
  {
    categoryGroup: 'allLogs'
    enabled: true
  }
] : contains(diagnosticLogCategoriesToEnable, '') ? [] : diagnosticsLogsSpecified

var diagnosticsMetrics = [for metric in diagnosticMetricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
}]

var identityType = systemAssignedIdentity ? (!empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned') : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None')

var identity = identityType != 'None' ? {
  type: identityType
  userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
} : null

resource app 'Microsoft.Web/sites@2022-09-01' = {
  name: name
  location: location
  kind: kind
  tags: tags
  identity: identity
  properties: {
    serverFarmId: serverFarmResourceId
    clientAffinityEnabled: clientAffinityEnabled
    httpsOnly: httpsOnly
    hostingEnvironmentProfile: !empty(appServiceEnvironmentResourceId) ? {
      id: appServiceEnvironmentResourceId
    } : null
    storageAccountRequired: storageAccountRequired
    keyVaultReferenceIdentity: !empty(keyVaultAccessIdentityResourceId) ? keyVaultAccessIdentityResourceId : null
    virtualNetworkSubnetId: !empty(virtualNetworkSubnetId) ? virtualNetworkSubnetId : any(null)
    siteConfig: siteConfig
    clientCertEnabled: clientCertEnabled
    clientCertExclusionPaths: !empty(clientCertExclusionPaths) ? clientCertExclusionPaths : null
    clientCertMode: clientCertMode
    cloningInfo: !empty(cloningInfo) ? cloningInfo : null
    containerSize: containerSize != -1 ? containerSize : null
    customDomainVerificationId: !empty(customDomainVerificationId) ? customDomainVerificationId : null
    dailyMemoryTimeQuota: dailyMemoryTimeQuota != -1 ? dailyMemoryTimeQuota : null
    enabled: enabled
    hostNameSslStates: hostNameSslStates
    hyperV: hyperV
    redundancyMode: redundancyMode
    publicNetworkAccess: !empty(publicNetworkAccess) ? any(publicNetworkAccess) : (!empty(privateEndpoints) ? 'Disabled' : 'Enabled')
    vnetContentShareEnabled: vnetContentShareEnabled
    vnetImagePullEnabled: vnetImagePullEnabled
    vnetRouteAllEnabled: vnetRouteAllEnabled
    scmSiteAlsoStopped: scmSiteAlsoStopped
  }
}

module app_appsettings 'config--appsettings/main.bicep' = if (!empty(appSettingsKeyValuePairs)) {
  name: '${uniqueString(deployment().name, location)}-Site-Config-AppSettings'
  params: {
    appName: app.name
    kind: kind
    storageAccountResourceId: storageAccountResourceId
    appInsightResourceId: appInsightResourceId
    setAzureWebJobsDashboard: setAzureWebJobsDashboard
    appSettingsKeyValuePairs: appSettingsKeyValuePairs
  }
}

module app_authsettingsv2 'config--authsettingsv2/main.bicep' = if (!empty(authSettingV2Configuration)) {
  name: '${uniqueString(deployment().name, location)}-Site-Config-AuthSettingsV2'
  params: {
    appName: app.name
    kind: kind
    authSettingV2Configuration: authSettingV2Configuration
  }
}

@batchSize(1)
module app_slots 'slot/main.bicep' = [for (slot, index) in slots: {
  name: '${uniqueString(deployment().name, location)}-Slot-${slot.name}'
  params: {
    name: slot.name
    appName: app.name
    location: location
    kind: kind
    serverFarmResourceId: serverFarmResourceId
    httpsOnly: contains(slot, 'httpsOnly') ? slot.httpsOnly : httpsOnly
    appServiceEnvironmentResourceId: !empty(appServiceEnvironmentResourceId) ? appServiceEnvironmentResourceId : ''
    clientAffinityEnabled: contains(slot, 'clientAffinityEnabled') ? slot.clientAffinityEnabled : clientAffinityEnabled
    systemAssignedIdentity: contains(slot, 'systemAssignedIdentity') ? slot.systemAssignedIdentity : systemAssignedIdentity
    userAssignedIdentities: contains(slot, 'userAssignedIdentities') ? slot.userAssignedIdentities : userAssignedIdentities
    keyVaultAccessIdentityResourceId: contains(slot, 'keyVaultAccessIdentityResourceId') ? slot.keyVaultAccessIdentityResourceId : keyVaultAccessIdentityResourceId
    storageAccountRequired: contains(slot, 'storageAccountRequired') ? slot.storageAccountRequired : storageAccountRequired
    virtualNetworkSubnetId: contains(slot, 'virtualNetworkSubnetId') ? slot.virtualNetworkSubnetId : virtualNetworkSubnetId
    siteConfig: contains(slot, 'siteConfig') ? slot.siteConfig : siteConfig
    storageAccountResourceId: contains(slot, 'storageAccountResourceId') ? slot.storageAccountResourceId : storageAccountResourceId
    appInsightResourceId: contains(slot, 'appInsightResourceId') ? slot.appInsightResourceId : appInsightResourceId
    setAzureWebJobsDashboard: contains(slot, 'setAzureWebJobsDashboard') ? slot.setAzureWebJobsDashboard : setAzureWebJobsDashboard
    authSettingV2Configuration: contains(slot, 'authSettingV2Configuration') ? slot.authSettingV2Configuration : authSettingV2Configuration
    diagnosticStorageAccountId: contains(slot, 'diagnosticStorageAccountId') ? slot.diagnosticStorageAccountId : diagnosticStorageAccountId
    diagnosticWorkspaceId: contains(slot, 'diagnosticWorkspaceId') ? slot.diagnosticWorkspaceId : diagnosticWorkspaceId
    diagnosticEventHubAuthorizationRuleId: contains(slot, 'diagnosticEventHubAuthorizationRuleId') ? slot.diagnosticEventHubAuthorizationRuleId : diagnosticEventHubAuthorizationRuleId
    diagnosticEventHubName: contains(slot, 'diagnosticEventHubName') ? slot.diagnosticEventHubName : diagnosticEventHubName
    diagnosticLogCategoriesToEnable: contains(slot, 'diagnosticLogCategoriesToEnable') ? slot.diagnosticLogCategoriesToEnable : diagnosticLogCategoriesToEnable
    diagnosticMetricsToEnable: contains(slot, 'diagnosticMetricsToEnable') ? slot.diagnosticMetricsToEnable : diagnosticMetricsToEnable
    appSettingsKeyValuePairs: contains(slot, 'appSettingsKeyValuePairs') ? slot.appSettingsKeyValuePairs : appSettingsKeyValuePairs
    privateEndpoints: contains(slot, 'privateEndpoints') ? slot.privateEndpoints : privateEndpoints
    tags: tags
    clientCertEnabled: contains(slot, 'clientCertEnabled') ? slot.clientCertEnabled : false
    clientCertExclusionPaths: contains(slot, 'clientCertExclusionPaths') ? slot.clientCertExclusionPaths : ''
    clientCertMode: contains(slot, 'clientCertMode') ? slot.clientCertMode : 'Optional'
    cloningInfo: contains(slot, 'cloningInfo') ? slot.cloningInfo : {}
    containerSize: contains(slot, 'containerSize') ? slot.containerSize : -1
    customDomainVerificationId: contains(slot, 'customDomainVerificationId') ? slot.customDomainVerificationId : ''
    dailyMemoryTimeQuota: contains(slot, 'dailyMemoryTimeQuota') ? slot.dailyMemoryTimeQuota : -1
    enabled: contains(slot, 'enabled') ? slot.enabled : true
    hostNameSslStates: contains(slot, 'hostNameSslStates') ? slot.hostNameSslStates : []
    hyperV: contains(slot, 'hyperV') ? slot.hyperV : false
    publicNetworkAccess: contains(slot, 'publicNetworkAccess') ? slot.publicNetworkAccess : ''
    redundancyMode: contains(slot, 'redundancyMode') ? slot.redundancyMode : 'None'
    vnetContentShareEnabled: contains(slot, 'vnetContentShareEnabled') ? slot.vnetContentShareEnabled : false
    vnetImagePullEnabled: contains(slot, 'vnetImagePullEnabled') ? slot.vnetImagePullEnabled : false
    vnetRouteAllEnabled: contains(slot, 'vnetRouteAllEnabled') ? slot.vnetRouteAllEnabled : false
    hybridConnectionRelays: contains(slot, 'hybridConnectionRelays') ? slot.hybridConnectionRelays : []
  }
}]

module app_basicPublishingCredentialsPolicies 'basic-publishing-credentials-policy/main.bicep' = [for (basicPublishingCredentialsPolicy, index) in basicPublishingCredentialsPolicies: {
  name: '${uniqueString(deployment().name, location)}-Site-Publis-Cred-${index}'
  params: {
    webAppName: app.name
    name: basicPublishingCredentialsPolicy.name
  }
}]

module app_hybridConnectionRelays 'hybrid-connection-namespace/relay/main.bicep' = [for (hybridConnectionRelay, index) in hybridConnectionRelays: {
  name: '${uniqueString(deployment().name, location)}-HybridConnectionRelay-${index}'
  params: {
    hybridConnectionResourceId: hybridConnectionRelay.resourceId
    appName: app.name
    sendKeyName: contains(hybridConnectionRelay, 'sendKeyName') ? hybridConnectionRelay.sendKeyName : null
  }
}]

resource app_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticStorageAccountId) || !empty(diagnosticWorkspaceId) || !empty(diagnosticEventHubAuthorizationRuleId) || !empty(diagnosticEventHubName)) {
  name: !empty(diagnosticSettingsName) ? diagnosticSettingsName : '${name}-diagnosticSettings'
  properties: {
    storageAccountId: !empty(diagnosticStorageAccountId) ? diagnosticStorageAccountId : null
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    eventHubAuthorizationRuleId: !empty(diagnosticEventHubAuthorizationRuleId) ? diagnosticEventHubAuthorizationRuleId : null
    eventHubName: !empty(diagnosticEventHubName) ? diagnosticEventHubName : null
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
  }
  scope: app
}

module app_privateEndpoints '../../network/private-endpoint/main.bicep' = [for (privateEndpoint, index) in (privateEndpoints ?? []): {
  name: '${uniqueString(deployment().name, location)}-app-PrivateEndpoint-${index}'
  params: {
    groupIds: [
      privateEndpoint.?service ?? 'sites'
    ]
    name: privateEndpoint.?name ?? 'pep-${last(split(app.id, '/'))}-${privateEndpoint.?service ?? 'sites'}-${index}'
    serviceResourceId: app.id
    subnetResourceId: privateEndpoint.subnetResourceId
    location: privateEndpoint.?location ?? reference(split(privateEndpoint.subnetResourceId, '/subnets/')[0], '2020-06-01', 'Full').location
    tags: privateEndpoint.?tags ?? tags
    manualPrivateLinkServiceConnections: privateEndpoint.?manualPrivateLinkServiceConnections
    customDnsConfigs: privateEndpoint.?customDnsConfigs
    ipConfigurations: privateEndpoint.?ipConfigurations
    customNetworkInterfaceName: privateEndpoint.?customNetworkInterfaceName
  }
}]

@description('The name of the site.')
output name string = app.name

@description('The resource ID of the site.')
output resourceId string = app.id

@description('The list of the slots.')
output slots array = [for (slot, index) in slots: app_slots[index].name]

@description('The list of the slot resource ids.')
output slotResourceIds array = [for (slot, index) in slots: app_slots[index].outputs.resourceId]

@description('The resource group the site was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The principal ID of the system assigned identity.')
output systemAssignedPrincipalId string = systemAssignedIdentity && contains(app.identity, 'principalId') ? app.identity.principalId : ''

@description('The principal ID of the system assigned identity of slots.')
output slotSystemAssignedPrincipalIds array = [for (slot, index) in slots: app_slots[index].outputs.systemAssignedPrincipalId]

@description('The location the resource was deployed into.')
output location string = app.location

@description('Default hostname of the app.')
output defaultHostname string = app.properties.defaultHostName

// =============== //
//   Definitions   //
// =============== //

type privateEndpointType = {
  @description('Optional. The name of the private endpoint.')
  name: string?

  @description('Optional. The location to deploy the private endpoint to.')
  location: string?

  @description('Optional. The service (sub-) type to deploy the private endpoint for. For example "vault" or "blob".')
  service: string?

  @description('Required. Resource ID of the subnet where the endpoint needs to be created.')
  subnetResourceId: string

  @description('Optional. The name of the private DNS zone group to create if privateDnsZoneResourceIds were provided.')
  privateDnsZoneGroupName: string?

  @description('Optional. The private DNS zone groups to associate the private endpoint with. A DNS zone group can support up to 5 DNS zones.')
  privateDnsZoneResourceIds: string[]?

  @description('Optional. Custom DNS configurations.')
  customDnsConfigs: {
    fqdn: string?
    ipAddresses: string[]
  }[]?

  @description('Optional. A list of IP configurations of the private endpoint. This will be used to map to the First Party Service endpoints.')
  ipConfigurations: {
    name: string
    groupId: string
    memberName: string
    privateIpAddress: string
  }[]?

  @description('Optional. Application security groups in which the private endpoint IP configuration is included.')
  applicationSecurityGroupResourceIds: string[]?

  @description('Optional. The custom name of the network interface attached to the private endpoint.')
  customNetworkInterfaceName: string?

  @description('Optional. Tags to be applied on all resources/resource groups in this deployment.')
  tags: object?

  @description('Optional. Manual PrivateLink Service Connections.')
  manualPrivateLinkServiceConnections: array?
}[]?
