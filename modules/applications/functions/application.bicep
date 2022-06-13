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

@description('The application type')
@allowed([
  'isolatedDotnet6'
])
param applicationType string

@description('The server farm ID')
param serverFarmId string

@description('The Azure WebJobs Storage Account name')
param webJobsStorageAccountName string

@description('The Key Vault vault URI')
param kvVaultUri string

@description('The Application Insights connection string')
param aiConnectionString string

@description('The Service Bus Namespace name')
param serviceBusNamespaceName string = ''

@description('The application packages URI')
param applicationPackageUri string = ''

@description('The application secret names')
param extraAppSettings object = {}

@description('The extra user-assigned identities to be used by the application')
param extraIdentities object = {}

@description('The OpenID configuration for authentication')
param openIdConfiguration object = {}

@description('The deployment location')
param location string

// === VARIABLES ===

var enableOpenId = contains(openIdConfiguration, 'clientSecretKey') && contains(openIdConfiguration, 'endpoint') && contains(openIdConfiguration, 'apiClientId')
var dailyMemoryTimeQuota = pricingPlan == 'Free' ? '10000' : pricingPlan == 'Basic' ? '1000000' : 'ERROR' // in GB.s/d
var linuxFxVersion = applicationType == 'isolatedDotnet6' ? 'DOTNET-ISOLATED|6.0' : 'ERROR'

var formattedExtraAppSettings = json(replace(replace(string(extraAppSettings), '<secret>', '@Microsoft.KeyVault(SecretUri=${kvVaultUri}secrets/'), '</secret>', ')'))
var formattedOpenIdSecret = enableOpenId ? replace(replace(openIdConfiguration.clientSecretKey, '<secret>', '@Microsoft.KeyVault(SecretUri=${kvVaultUri}secrets/'), '</secret>', ')') : ''
var appSettings = union(formattedExtraAppSettings, {
  // General hosting information
  'AZURE_FUNCTIONS_ORGANIZATION': referential.organization
  'AZURE_FUNCTIONS_APPLICATION': referential.application
  'AZURE_FUNCTIONS_ENVIRONMENT': referential.environment
  'AZURE_FUNCTIONS_HOST': referential.host
  'AZURE_FUNCTIONS_REGION': referential.region
  // Functions runtime configuration
  'FUNCTIONS_EXTENSION_VERSION': applicationType == 'isolatedDotnet6' ? '~4' : 'ERROR'
  'FUNCTIONS_WORKER_RUNTIME': applicationType == 'isolatedDotnet6' ? 'dotnet-isolated' : 'ERROR'
  // Functions misc configuration
  'AzureWebJobsDisableHomepage': 'true'
  // Connection information for Storage Account (triggers management)
  'AzureWebJobsStorage__accountName': webJobsStorageAccountName
  'AzureWebJobsStorage__credential': 'managedidentity'
  'AzureWebJobsStorage__clientId': userAssignedIdentityClientId
  // Application Insights configuration
  'APPLICATIONINSIGHTS_CONNECTION_STRING': aiConnectionString
  // Application deployment package authorization
  'WEBSITE_RUN_FROM_PACKAGE_BLOB_MI_RESOURCE_ID': userAssignedIdentityId
  // Application identity configuration
  'AZURE_CLIENT_ID': userAssignedIdentityClientId
}, empty(serviceBusNamespaceName) ? {} : {
  // Connection information for Service Bus namespace
  'AzureWebJobsServiceBus__fullyQualifiedNamespace': '${serviceBusNamespaceName}.servicebus.windows.net'
  'AzureWebJobsServiceBus__credential': 'managedidentity'
  'AzureWebJobsServiceBus__clientId': userAssignedIdentityClientId
}, empty(applicationPackageUri) ? {} : {
  // Application deployment package URI
  'WEBSITE_RUN_FROM_PACKAGE': applicationPackageUri
}, enableOpenId ? {} : {
  'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET': formattedOpenIdSecret
})

var slotAppSettingNames = [
  'AZURE_FUNCTIONS_HOST'
]

var userAssignedIdentities = union({
  '${userAssignedIdentityId}': {}
}, extraIdentities)

// === RESOURCES ===

@description('Functions application')
resource fn 'Microsoft.Web/sites@2021-03-01' = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.functionsApplication}'
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: userAssignedIdentities
  }
  tags: referential
  properties: {
    serverFarmId: serverFarmId
    reserved: true
    httpsOnly: true
    dailyMemoryTimeQuota: json(dailyMemoryTimeQuota)
    keyVaultReferenceIdentity: userAssignedIdentityId
  }

  // Web Configuration
  resource webConfig 'config' = {
    name: 'web'
    properties: {
      linuxFxVersion: linuxFxVersion
      localMySqlEnabled: false
      http20Enabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'Disabled'
    }
  }

  // App Configuration
  resource appsettingsConfig 'config' = {
    name: 'appsettings'
    properties: appSettings
  }

  // Slot settings
  resource slotConfigNamesConfig 'config' = {
    name: 'slotConfigNames'
    properties: {
      appSettingNames: slotAppSettingNames
    }
  }

  // Authentication
  resource aa 'config' = if (enableOpenId) {
    name: 'authsettingsV2'
    properties: {
      platform: {
        enabled: true
      }
      globalValidation: {
        requireAuthentication: true
        unauthenticatedClientAction: 'Return401'
        excludedPaths: [
          '/api/health'
          '/api/health/light'
        ]
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
            clientId: openIdConfiguration.apiClientId
            clientSecretSettingName: 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
            openIdIssuer: openIdConfiguration.endpoint
          }
        }
      }
    }
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = fn.id

@description('The API Version of the deployed resource')
output apiVersion string = fn.apiVersion

@description('The Name of the deployed resource')
output name string = fn.name

@description('The default host name if the deployed resource')
output defaultHostName string = fn.properties.defaultHostName
