// Deploy an App Configuration
// Resources deployed from this template:
//   - App Configuration
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
var appConfigurationName = '${tags.organization}-${tags.application}-${tags.host}-cfg'

// === RESOURCES ===

// App Configuration
resource appConfig 'Microsoft.AppConfiguration/configurationStores@2021-03-01-preview' = {
  name: appConfigurationName
  location: location
  sku: {
    name: 'free'
  }
  tags: resourceGroup().tags
  properties: {
    disableLocalAuth: false
  }
}

// === OUTPUTS ===

output id string = appConfig.id
output apiVersion string = appConfig.apiVersion
output name string = appConfig.name
