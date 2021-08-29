// Deploy a Server farm
// Resources deployed from this template:
//   - Server farm
// Required parameters:
//   [None]
// Optional parameters:
//   [None]
// Outputs:
//   - `id`
//   - `apiVersion`
//   - `name`

// === VARIABLES ===

var location = resourceGroup().location
var tags = resourceGroup().tags
var hostingPlanName = '${tags.organization}-${tags.application}-${tags.host}-asp'

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
  tags: resourceGroup().tags
  properties: {
    reserved: true // Linux App Service
  }
}

// === OUTPUTS ===

output id string = farm.id
output apiVersion string = farm.apiVersion
output name string = farm.name
