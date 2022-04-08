/*
  Deploy a Service Plan
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The deployment location')
param location string

// === RESOURCES ===

@description('Service Plan')
resource servicePlan 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.servicePlan}'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  kind: 'functionapp'
  tags: referential
  properties: {
    reserved: true // Linux App Service
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = servicePlan.id

@description('The API Version of the deployed resource')
output apiVersion string = servicePlan.apiVersion

@description('The Name of the deployed resource')
output name string = servicePlan.name
