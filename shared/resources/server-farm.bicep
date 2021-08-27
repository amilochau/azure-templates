// Deploy a Server farm
// Resources deployed from this template:
//   - Server farm
// Required parameters:
//   - `organizationName`
//   - `applicationName`
//   - `environmentName`
//   - `hostName`
// Optional parameters:
//   [None]
// Outputs:
//   - `id`
//   - `apiVersion`
//   - `name`

// === PARAMETERS ===

@description('The organization name')
param organizationName string

@description('The application name')
param applicationName string

@description('The environment name of the deployment stage')
param environmentName string

@description('The host name of the deployment stage')
param hostName string

// === VARIABLES ===

var location = resourceGroup().location
var hostingPlanName = '${organizationName}-${applicationName}-${hostName}-asp'

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
  properties: {
    reserved: true // Linux App Service
  }
}

// === OUTPUTS ===

output id string = farm.id
output apiVersion string = farm.apiVersion
output name string = farm.name
