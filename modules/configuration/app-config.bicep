/*
  Deploy an App Configuration
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The pricing plan')
@allowed([
  'Free'    // The cheapest plan, can create some small fees
  'Basic'   // Basic use with default limitations
])
param pricingPlan string

// === VARIABLES ===

var location = resourceGroup().location
var appConfigurationSku = pricingPlan == 'Free' ? 'free' : pricingPlan == 'Basic' ? 'standard' : 'ERROR'

// === RESOURCES ===

@description('App Configuration')
resource appConfig 'Microsoft.AppConfiguration/configurationStores@2021-03-01-preview' = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.appConfiguration}'
  location: location
  sku: {
    name: appConfigurationSku
  }
  tags: referential
  properties: {
    disableLocalAuth: false
    /* Two limitations to put this 'disableLocalAuth' settings to 'true':
      1/ ARM template won't work well: https://docs.microsoft.com/en-us/azure/azure-app-configuration/howto-disable-access-key-authentication?tabs=portal#arm-template-access
      2/ Configuration keys deployment won't work well from GitHub Actions: https://github.com/marketplace/actions/azure-app-configuration-sync#connection-string
    */
  }
}

// === OUTPUTS ===

@description('The ID of the deployed App Configuration')
output id string = appConfig.id

@description('The API Version of the deployed App Configuration')
output apiVersion string = appConfig.apiVersion

@description('The Name of the deployed App Configuration')
output name string = appConfig.name
