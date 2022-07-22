/*
  Deploy a Functions application
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

@description('The ID of the User-Assigned Identity to use')
param userAssignedIdentityId string

@description('The Client ID of the User-Assigned Identity to use')
param userAssignedIdentityClientId string

@description('The Functions app options')
param functionsAppOptions object

@description('The server farm ID')
param serverFarmId string

@description('The Azure WebJobs Storage Account name')
param webJobsStorageAccountName string

@description('The Key Vault vault URI')
param kvVaultUri string

@description('The Application Insights connection string')
param aiConnectionString string

@description('The Service Bus Namespace name')
param serviceBusNamespaceName string

@description('The application package URI')
param applicationPackageUri string

@description('The deployment location')
param location string

// === VARIABLES ===

// General settings
var dailyMemoryTimeQuota = pricingPlan == 'Free' ? '10000' : pricingPlan == 'Basic' ? '1000000' : 'ERROR' // in GB.s/d
var linuxFxVersion = functionsAppOptions.stack == 'isolatedDotnet6' ? 'DOTNET-ISOLATED|6.0' : 'ERROR'

// OpenID
var enableOpenId = contains(functionsAppOptions, 'openId')
var formattedOpenIdSecret = enableOpenId ? replace(replace(functionsAppOptions.openId.clientSecretKey, '<secret>', '@Microsoft.KeyVault(SecretUri=${kvVaultUri}secrets/'), '</secret>', ')') : ''
var defaultAnonymousEndpoints = loadJsonContent('../../global/anonymous-endpoints.json')

// Identity settings
var extraIdentities = contains(functionsAppOptions, 'extraIdentities') ? functionsAppOptions.extraIdentities : {}
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
  dailyMemoryTimeQuota: json(dailyMemoryTimeQuota)
  keyVaultReferenceIdentity: userAssignedIdentityId
}

// Web settings
var webSettings = {
  linuxFxVersion: linuxFxVersion
  localMySqlEnabled: false
  http20Enabled: true
  minTlsVersion: '1.2'
  scmMinTlsVersion: '1.2'
  ftpsState: 'Disabled'
}

// App settings
var extraAppSettings = contains(functionsAppOptions, 'extraAppSettings') ? functionsAppOptions.extraAppSettings : {}
var formattedExtraAppSettings = json(replace(replace(string(extraAppSettings), '<secret>', '@Microsoft.KeyVault(SecretUri=${kvVaultUri}secrets/'), '</secret>', ')'))
var appSettings = union(formattedExtraAppSettings, {
  // General hosting information
  AZURE_FUNCTIONS_ORGANIZATION: referential.organization
  AZURE_FUNCTIONS_APPLICATION: referential.application
  AZURE_FUNCTIONS_ENVIRONMENT: referential.environment
  AZURE_FUNCTIONS_HOST: referential.host
  AZURE_FUNCTIONS_REGION: referential.region
  // Functions runtime configuration
  FUNCTIONS_EXTENSION_VERSION: functionsAppOptions.stack == 'isolatedDotnet6' ? '~4' : 'ERROR'
  FUNCTIONS_WORKER_RUNTIME: functionsAppOptions.stack == 'isolatedDotnet6' ? 'dotnet-isolated' : 'ERROR'
  // Functions misc configuration
  AzureWebJobsDisableHomepage: 'true'
  // Connection information for Storage Account (triggers management)
  AzureWebJobsStorage__accountName: webJobsStorageAccountName
  AzureWebJobsStorage__credential: 'managedidentity'
  AzureWebJobsStorage__clientId: userAssignedIdentityClientId
  // Application Insights configuration
  APPLICATIONINSIGHTS_CONNECTION_STRING: aiConnectionString
  // Application deployment package authorization
  WEBSITE_RUN_FROM_PACKAGE_BLOB_MI_RESOURCE_ID: userAssignedIdentityId
  // Application identity configuration
  AZURE_CLIENT_ID: userAssignedIdentityClientId
}, empty(serviceBusNamespaceName) ? {} : {
  // Connection information for Service Bus namespace
  AzureWebJobsServiceBus__fullyQualifiedNamespace: '${serviceBusNamespaceName}.servicebus.windows.net'
  AzureWebJobsServiceBus__credential: 'managedidentity'
  AzureWebJobsServiceBus__clientId: userAssignedIdentityClientId
}, empty(applicationPackageUri) ? {} : {
  // Application deployment package URI
  WEBSITE_RUN_FROM_PACKAGE: applicationPackageUri
}, !enableOpenId ? {} : {
  MICROSOFT_PROVIDER_AUTHENTICATION_SECRET: formattedOpenIdSecret
})

// Slot settings
var slotSettings = {
  appSettingNames: [
    'AZURE_FUNCTIONS_HOST'
  ]
}

// Auth settings
var authSettings = enableOpenId ? {
  platform: {
    enabled: true
  }
  globalValidation: contains(functionsAppOptions.openId, 'skipAuthentication') && functionsAppOptions.openId.skipAuthentication ? {
    requireAuthentication: false
    unauthenticatedClientAction: 'AllowAnonymous'
  } : {
    requireAuthentication: true
    unauthenticatedClientAction: 'Return401'
    excludedPaths: contains(functionsAppOptions.openId, 'anonymousEndpoints') ? union(defaultAnonymousEndpoints, functionsAppOptions.openId.anonymousEndpoints) : defaultAnonymousEndpoints
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
        clientId: functionsAppOptions.openId.apiClientId
        clientSecretSettingName: 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
        openIdIssuer: functionsAppOptions.openId.endpoint
      }
    }
  }
} : {}

// === RESOURCES ===

@description('Functions application')
resource fn 'Microsoft.Web/sites@2021-03-01' = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.functionsApplication}'
  location: location
  kind: 'functionapp,linux'
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
}

@description('The extra deployment slots')
module slots './application-slot.bicep' = [for deploymentSlot in functionsAppOptions.extraSlots: if (contains(functionsAppOptions, 'extraSlots')) {
  name: 'Resource-FunctionsSlot-${deploymentSlot.name}'
  params: {
    referential: referential
    functionsName: fn.name
    slotName: deploymentSlot.name
    identitySettings: identitySettings
    siteSettings: siteSettings
    webSettings: webSettings
    appSettings: appSettings
    authSettings: authSettings
    enableOpenId: enableOpenId
    location: location
  }
}]

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = fn.id

@description('The API Version of the deployed resource')
output apiVersion string = fn.apiVersion

@description('The Name of the deployed resource')
output name string = fn.name

@description('The default host name if the deployed resource')
output defaultHostName string = fn.properties.defaultHostName
