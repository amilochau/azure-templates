/*
  Deploy a Server farm
  Resources deployed from this template:
    - Server farm
  Required parameters:
    - `referential`
  Optional parameters:
    [None]
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

// === VARIABLES ===

var location = resourceGroup().location
var hostingPlanName = '${referential.organization}-${referential.application}-${referential.host}-asp'

// === RESOURCES ===

// Server farm
resource farm 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: hostingPlanName
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
