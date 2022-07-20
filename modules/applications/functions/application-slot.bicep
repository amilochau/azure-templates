/*
  Deploy a Functions application slot
*/

// === PARAMETERS ===


@description('The referential, from the tags.bicep module')
param referential object

@description('The parent Functions application name')
param functionsName string

@description('The slot name')
param slotName string

@description('The "identity" settings of the parent Functions application')
param identitySettings object

@description('The "properties" settings of the parent Functions application')
param siteSettings object

@description('The "web" config settings of the parent Functions application')
param webSettings object

@description('The "appsettings" config settings of the parent Functions application')
param appSettings object

@description('The "authsettingsV2" config settings of the parent Functions application')
param authSettings object

@description('Whether OpenID must be enabled as auth settings')
param enableOpenId bool

@description('The deployment location')
param location string

// === VARIABLES ===

var slotAppSettings = union(appSettings, {
  AZURE_FUNCTIONS_HOST: slotName
})

// === EXISTING ===

@description('Functions application')
resource fn 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionsName
}

// === RESOURCES ===

@description('Functions application')
resource fnSlot 'Microsoft.Web/sites/slots@2021-03-01' = {
  name: slotName
  parent: fn
  location: location
  identity: identitySettings
  tags: referential
  properties: siteSettings

  // Web Configuration
  resource webConfig 'config' = {
    name: 'web'
    properties: webSettings
  }

  // App Configuration
  resource appsettingsConfig 'config' = {
    name: 'appsettings'
    properties: slotAppSettings
  }

  // Authentication
  resource authSettingsConfig 'config' = if (enableOpenId) {
    name: 'authsettingsV2'
    properties: authSettings
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = fnSlot.id

@description('The API Version of the deployed resource')
output apiVersion string = fnSlot.apiVersion

@description('The Name of the deployed resource')
output name string = fnSlot.name

@description('The default host name if the deployed resource')
output defaultHostName string = fnSlot.properties.defaultHostName
