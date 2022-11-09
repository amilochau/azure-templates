/*
  Deploy a Web application slot
*/

// === PARAMETERS ===


@description('The referential, from the tags.bicep module')
param referential object

@description('The parent application name')
param applicationName string

@description('The slot name')
param slotName string

@description('The "identity" settings of the parent application')
param identitySettings object

@description('The "properties" settings of the parent application')
param siteSettings object

@description('The "web" config settings of the parent application')
param webSettings object

@description('The "appsettings" config settings of the parent application')
param appSettings object

@description('The "authsettingsV2" config settings of the parent application')
param authSettings object

@description('Whether OpenID must be enabled as auth settings')
param enableOpenId bool

@description('The deployment location')
param location string

// === VARIABLES ===

var slotAppSettings = union(appSettings, {
  ASPNETCORE_HOST: slotName
})

// === EXISTING ===

@description('Application')
resource site 'Microsoft.Web/sites@2022-03-01' existing = {
  name: applicationName
}

// === RESOURCES ===

@description('Application slot')
resource siteSlot 'Microsoft.Web/sites/slots@2022-03-01' = {
  name: slotName
  parent: site
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
output id string = siteSlot.id

@description('The API Version of the deployed resource')
output apiVersion string = siteSlot.apiVersion

@description('The Name of the deployed resource')
output name string = siteSlot.name

@description('The default host name if the deployed resource')
output defaultHostName string = siteSlot.properties.defaultHostName
