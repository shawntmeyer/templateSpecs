metadata name = 'Policy Exemptions (All scopes)'
metadata description = 'This module deploys a Policy Exemption at a Management Group, Subscription or Resource Group scope.'
metadata owner = 'Azure/module-maintainers'

targetScope = 'managementGroup'

@sys.description('Required. Specifies the name of the policy exemption. Maximum length is 64 characters for management group, subscription and resource group scopes.')
@maxLength(64)
param name string

@sys.description('Optional. The display name of the policy exemption. Maximum length is 128 characters.')
@maxLength(128)
param displayName string = ''

@sys.description('Optional. The description of the policy exemption.')
param description string = ''

@sys.description('Optional. The policy exemption metadata. Metadata is an open ended object and is typically a collection of key-value pairs.')
param metadata object = {}

@sys.description('Optional. The policy exemption category. Possible values are Waiver and Mitigated. Default is Mitigated.')
@allowed([
  'Mitigated'
  'Waiver'
])
param exemptionCategory string = 'Mitigated'

@sys.description('Required. The resource ID of the policy assignment that is being exempted.')
param policyAssignmentId string

@sys.description('Optional. The policy definition reference ID list when the associated policy assignment is an assignment of a policy set definition.')
param policyDefinitionReferenceIds array = []

@sys.description('Optional. The expiration date and time (in UTC ISO 8601 format yyyy-MM-ddTHH:mm:ssZ) of the policy exemption. e.g. 2021-10-02T03:57:00.000Z.')
param expiresOn string = ''

@sys.description('Optional. The group ID of the management group to be exempted from the policy assignment. If not provided, will use the current scope for deployment.')
param managementGroupId string = managementGroup().name

@sys.description('Optional. The subscription ID of the subscription to be exempted from the policy assignment. Cannot use with management group ID parameter.')
param subscriptionId string = ''

@sys.description('Optional. The name of the resource group to be exempted from the policy assignment. Must also use the subscription ID parameter.')
param resourceGroupName string = ''

@sys.description('Optional. Location deployment metadata.')
param location string = deployment().location

@sys.description('Optional. The option whether validate the exemption is at or under the assignment scope.')
@allowed([
  ''
  'Default'
  'DoNotValidate'
])
param assignmentScopeValidation string = ''

@sys.description('Optional. The resource selector list to filter policies by resource properties.')
param resourceSelectors array = []

module policyExemption_mg 'management-group/main.bicep' = if (empty(subscriptionId) && empty(resourceGroupName)) {
  name: '${uniqueString(deployment().name, location)}-PolicyExemption-MG-Module'
  scope: managementGroup(managementGroupId)
  params: {
    name: name
    displayName: displayName
    description: description
    metadata: metadata
    exemptionCategory: exemptionCategory
    policyAssignmentId: policyAssignmentId
    policyDefinitionReferenceIds: policyDefinitionReferenceIds
    expiresOn: expiresOn
    assignmentScopeValidation: assignmentScopeValidation
    resourceSelectors: resourceSelectors
  }
}

module policyExemption_sub 'subscription/main.bicep' = if (!empty(subscriptionId) && empty(resourceGroupName)) {
  name: '${uniqueString(deployment().name, location)}-PolicyExemption-Sub-Module'
  scope: subscription(subscriptionId)
  params: {
    name: name
    displayName: displayName
    description: description
    metadata: metadata
    exemptionCategory: exemptionCategory
    policyAssignmentId: policyAssignmentId
    policyDefinitionReferenceIds: policyDefinitionReferenceIds
    expiresOn: expiresOn
  }
}

module policyExemption_rg 'resource-group/main.bicep' = if (!empty(resourceGroupName) && !empty(subscriptionId)) {
  name: '${uniqueString(deployment().name, location)}-PolicyExemption-RG-Module'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    name: name
    displayName: displayName
    description: description
    metadata: metadata
    exemptionCategory: exemptionCategory
    policyAssignmentId: policyAssignmentId
    policyDefinitionReferenceIds: policyDefinitionReferenceIds
    expiresOn: expiresOn
  }
}

@sys.description('Policy Exemption Name.')
output name string = empty(subscriptionId) && empty(resourceGroupName) ? policyExemption_mg.outputs.name : (!empty(subscriptionId) && empty(resourceGroupName) ? policyExemption_sub.outputs.name : policyExemption_rg.outputs.name)

@sys.description('Policy Exemption resource ID.')
output resourceId string = empty(subscriptionId) && empty(resourceGroupName) ? policyExemption_mg.outputs.resourceId : (!empty(subscriptionId) && empty(resourceGroupName) ? policyExemption_sub.outputs.resourceId : policyExemption_rg.outputs.resourceId)

@sys.description('Policy Exemption Scope.')
output scope string = empty(subscriptionId) && empty(resourceGroupName) ? policyExemption_mg.outputs.scope : (!empty(subscriptionId) && empty(resourceGroupName) ? policyExemption_sub.outputs.scope : policyExemption_rg.outputs.scope)
