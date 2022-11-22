/*
  Deploy a Web application
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The ID of the User-Assigned Identity to use')
param userAssignedIdentityId string

@description('The Client ID of the User-Assigned Identity to use')
param userAssignedIdentityClientId string

@description('The Web app options')
param webAppOptions object

@description('The server farm ID')
param serverFarmId string

@description('The Key Vault vault URI')
param kvVaultUri string

@description('The Application Insights connection string')
param aiConnectionString string

@description('The application Docker image reference')
param applicationImageReference string

@description('The deployment location')
param location string

// === VARIABLES ===

// General settings
var extraSlots = contains(webAppOptions, 'extraSlots') ? webAppOptions.extraSlots : []
var alwaysOn = startsWith(referential.host, 'prd')

// OpenID
var enableOpenId = contains(webAppOptions, 'openId')
var formattedOpenIdSecret = enableOpenId ? replace(replace(webAppOptions.openId.clientSecretKey, '<secret>', '@Microsoft.KeyVault(SecretUri=${kvVaultUri}secrets/'), '</secret>', ')') : ''
var defaultAnonymousEndpoints = loadJsonContent('../../global/anonymous-endpoints.json')

// Identity settings
var extraIdentities = contains(webAppOptions, 'extraIdentities') ? webAppOptions.extraIdentities : {}
var identitySettings = {
  type: 'UserAssigned'
  userAssignedIdentities: union({
    '${userAssignedIdentityId}': {}
  }, extraIdentities)
}

// Site settings
var siteSettings = {
  serverFarmId: serverFarmId
  reserved: true
  httpsOnly: true
  keyVaultReferenceIdentity: userAssignedIdentityId
  clientAffinityEnabled: false
}

// Web settings
var enableHealthCheck = contains(webAppOptions, 'healthCheck')
var webSettings = {
  linuxFxVersion: applicationImageReference
  localMySqlEnabled: false
  http20Enabled: true
  minTlsVersion: '1.2'
  scmMinTlsVersion: '1.2'
  ftpsState: 'Disabled'
  healthCheckPath: enableHealthCheck ? webAppOptions.healthCheck.path : ''
  alwaysOn: alwaysOn
}

// App settings
var extraAppSettings = contains(webAppOptions, 'extraAppSettings') ? webAppOptions.extraAppSettings : {}
var dockerRegistryServerUrl = contains(webAppOptions.dockerRegistryServer, 'host') ? 'https://${webAppOptions.dockerRegistryServer.host}' : 'https://mcr.microsoft.com'
var dockerRegistryServerUsername = contains(webAppOptions.dockerRegistryServer, 'username') ? replace(replace(webAppOptions.dockerRegistryServer.username, '<secret>', '@Microsoft.KeyVault(SecretUri=${kvVaultUri}secrets/'), '</secret>', ')') : ''
var dockerRegistryServerPassword = contains(webAppOptions.dockerRegistryServer, 'password') ? replace(replace(webAppOptions.dockerRegistryServer.password, '<secret>', '@Microsoft.KeyVault(SecretUri=${kvVaultUri}secrets/'), '</secret>', ')') : ''
var formattedExtraAppSettings = json(replace(replace(string(extraAppSettings), '<secret>', '@Microsoft.KeyVault(SecretUri=${kvVaultUri}secrets/'), '</secret>', ')'))
var appSettings = union(formattedExtraAppSettings, {
  // General hosting information
  ASPNETCORE_ORGANIZATION: referential.organization
  ASPNETCORE_APPLICATION: referential.application
  ASPNETCORE_ENVIRONMENT: referential.environment
  ASPNETCORE_HOST: referential.host
  ASPNETCORE_REGION: referential.region
  // Application Insights configuration
  APPLICATIONINSIGHTS_CONNECTION_STRING: aiConnectionString
  // Application identity configuration
  AZURE_CLIENT_ID: userAssignedIdentityClientId
  // Docker application specific configuration
  DOCKER_REGISTRY_SERVER_URL: dockerRegistryServerUrl
  DOCKER_REGISTRY_SERVER_USERNAME: dockerRegistryServerUsername
  DOCKER_REGISTRY_SERVER_PASSWORD: dockerRegistryServerPassword
  WEBSITES_ENABLE_APP_SERVICE_STORAGE: false
}, !enableOpenId ? {} : {
  MICROSOFT_PROVIDER_AUTHENTICATION_SECRET: formattedOpenIdSecret
}, !enableHealthCheck ? {} : {
  WEBSITE_HEALTHCHECK_MAXPINGFAILURES: 5
})

// Slot settings
var slotSettings = {
  appSettingNames: [
    'ASPNETCORE_HOST'
  ]
}

// Auth settings
var authSettings = enableOpenId ? {
  platform: {
    enabled: true
  }
  globalValidation: contains(webAppOptions.openId, 'skipAuthentication') && webAppOptions.openId.skipAuthentication ? {
    requireAuthentication: false
    unauthenticatedClientAction: 'AllowAnonymous'
  } : {
    requireAuthentication: true
    unauthenticatedClientAction: 'Return401'
    excludedPaths: contains(webAppOptions.openId, 'anonymousEndpoints') ? union(defaultAnonymousEndpoints, webAppOptions.openId.anonymousEndpoints) : defaultAnonymousEndpoints
  }
  login: {
    tokenStore: {
      enabled: true
    }
  }
  httpSettings: {
    requireHttps: true
  }
  identityProviders: {
    azureActiveDirectory: {
      enabled: true
      registration: {
        clientId: webAppOptions.openId.apiClientId
        clientSecretSettingName: 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
        openIdIssuer: webAppOptions.openId.endpoint
      }
    }
  }
} : {}

// === RESOURCES ===

@description('Functions application')
resource app 'Microsoft.Web/sites@2022-03-01' = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.webApplication}'
  location: location
  kind: 'app,linux,container'
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
    properties: appSettings
  }

  // Slot settings
  resource slotConfigNamesConfig 'config' = {
    name: 'slotConfigNames'
    properties: slotSettings
  }

  // Authentication
  resource authSettingsConfig 'config' = if (enableOpenId) {
    name: 'authsettingsV2'
    properties: authSettings
  }

  resource basicPublishingCredentialsPoliciesFtp 'basicPublishingCredentialsPolicies' = {
    name: 'ftp'
    properties: {
      allow: false
    }
  }

  resource basicPublishingCredentialsPoliciesScm 'basicPublishingCredentialsPolicies' = {
    name: 'scm'
    properties: {
      allow: false
    }
  }
}

@description('The extra deployment slots')
module slots '../application-slot.bicep' = [for deploymentSlot in extraSlots: if (contains(webAppOptions, 'extraSlots')) {
  name: 'Resource-FunctionsSlot-${deploymentSlot.name}'
  params: {
    referential: referential
    applicationName: app.name
    slotName: deploymentSlot.name
    identitySettings: identitySettings
    siteSettings: siteSettings
    webSettings: webSettings
    appSettings: union(appSettings, {
      ASPNETCORE_HOST: deploymentSlot.name
    })
    authSettings: authSettings
    enableOpenId: enableOpenId
    location: location
  }
}]

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = app.id

@description('The API Version of the deployed resource')
output apiVersion string = app.apiVersion

@description('The Name of the deployed resource')
output name string = app.name

@description('The default host name of the deployed resource')
output defaultHostName string = app.properties.hostNames[0]
