/*
  Deploy a Service Plan
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

// === VARIABLES ===

var location = resourceGroup().location

// === RESOURCES ===

@description('Service Plan')
resource farm 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: conventions.naming.servicePlan.name
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

output id string = farm.id
output apiVersion string = farm.apiVersion
output name string = farm.name
