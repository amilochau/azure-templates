// Get references from a shared Azure App Configuration
// Resources deployed from this template:
//   [None]
// Optional parameters:
//   - `appConfigurationName`
// Outputs:
//   - `id`
//   - `apiVersion`
//   - `name`
//   - `endpoint`

// === PARAMETERS ===

@description('App Configuration name')
param appConfigurationName string

// === VARIABLES ===

// === RESOURCES ===

resource appConfig 'Microsoft.AppConfiguration/configurationStores@2021-03-01-preview' existing = {
  name: appConfigurationName
}

// === OUTPUTS ===

output id string = appConfig.id
output apiVersion string = appConfig.apiVersion
output name string = appConfig.name
output endpoint string = appConfig.properties.endpoint
