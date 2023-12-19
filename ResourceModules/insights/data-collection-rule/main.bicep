metadata name = 'Data Collection Rules'
metadata description = 'This module deploys a Data Collection Rule.'
metadata owner = 'shmeyer@microsoft.com'

// ============== //
//   Parameters   //
// ============== //

@sys.description('Required. The name of the data collection rule. The name is case insensitive.')
param name string

@sys.description('Optional. The resource ID of the data collection endpoint that this rule can be used with.')
param dataCollectionEndpointId string = ''

@sys.description('Required. The specification of data flows.')
param dataFlows array

@sys.description('Required. Specification of data sources that will be collected.')
param dataSources object

@sys.description('Optional. Description of the data collection rule.')
param description string = ''

@sys.description('Required. Specification of destinations that can be used in data flows.')
param destinations object

@sys.description('Optional. The kind of the resource.')
@allowed([
  'Linux'
  'Windows'
])
param kind string = 'Linux'

@sys.description('Optional. Location for all Resources.')
param location string = resourceGroup().location

@sys.description('Optional. Declaration of custom streams used in this rule.')
param streamDeclarations object = {}

@sys.description('Optional. Resource tags.')
param tags object?

// =============== //
//   Deployments   //
// =============== //

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2021-09-01-preview' = {
  kind: kind
  location: location
  name: name
  tags: tags
  properties: {
    dataSources: dataSources
    destinations: destinations
    dataFlows: dataFlows
    dataCollectionEndpointId: !empty(dataCollectionEndpointId) ? dataCollectionEndpointId : null
    streamDeclarations: !empty(streamDeclarations) ? streamDeclarations : null
    description: !empty(description) ? description : null
  }
}

// =========== //
//   Outputs   //
// =========== //

@sys.description('The name of the dataCollectionRule.')
output name string = dataCollectionRule.name

@sys.description('The resource ID of the dataCollectionRule.')
output resourceId string = dataCollectionRule.id

@sys.description('The name of the resource group the dataCollectionRule was created in.')
output resourceGroupName string = resourceGroup().name

@sys.description('The location the resource was deployed into.')
output location string = dataCollectionRule.location
