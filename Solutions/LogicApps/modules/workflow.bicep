param workflowName string
param location string
param parameters object = {}
param tags object = {}
param zoneRedundancy string = ''

resource workflow 'Microsoft.Logic/workflows@2016-10-01' = {
  name: workflowName
  location: location
  properties: {
    definition: {
      '\$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
    }
    parameters: parameters
    zoneRedundancy: !empty(zoneRedundancy) ? zoneRedundancy : null
  }
  tags: contains(tags, 'Microsoft.Logic/workflows') ? tags['Microsoft.Logic/workflows'] : {}
}
