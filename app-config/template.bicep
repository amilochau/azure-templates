// Deploy infrastructure for Azure App Configuration
// Resources deployed from this template:
//   - App Configuration
// Required parameters:
//   - `appConfigurationName`
// Outputs:
//   [None]

// === PARAMETERS ===

@description('The App Configuration name')
param appConfigurationName string

// === VARIABLES ===

var location = resourceGroup().location

// === RESOURCES ===

resource appConfig 'Microsoft.AppConfiguration/configurationStores@2021-03-01-preview' = {
  name: appConfigurationName
  location: location
  sku: {
    name: 'free'
  }
  properties: {
    disableLocalAuth: false
  }
}
