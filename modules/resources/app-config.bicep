/*
  Deploy an App Configuration
  Resources deployed from this template:
    - App Configuration
  Required parameters:
    - `referential`
    - `appConfigurationName`
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

@description('The App Configuration name')
param appConfigurationName string

// === VARIABLES ===

var location = resourceGroup().location

// === RESOURCES ===

// App Configuration
resource appConfig 'Microsoft.AppConfiguration/configurationStores@2021-03-01-preview' = {
  name: appConfigurationName
  location: location
  sku: {
    name: 'free'
  }
  tags: referential
  properties: {
    disableLocalAuth: false
  }
}

// === OUTPUTS ===

output id string = appConfig.id
output apiVersion string = appConfig.apiVersion
output name string = appConfig.name
