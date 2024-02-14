targetScope = 'subscription'
param vNets array
param outboundSubnets array
param peSubnets array
param newSubnets array
param resourceGroup object

param testwithoutFilter array
param minorVersionsFiltered array

var resourceGroupObjectExisting = '{"mode":"Existing","value":{"name":"rg-TemplateSpecs","location":"eastus","provisioningState":"Succeeded"}}'
var resourceGroupObjectNew = '{"mode":"New","value":{"name":"rg-TemplateSpecs","location":"eastus","provisioningState":"Succeeded"}}'

