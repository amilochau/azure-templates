/*
  Deploy a Functions application slot
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The pricing plan')
@allowed([
  'Free'    // The cheapest plan, can create some small fees
  'Basic'   // Basic use with default limitations
])
param pricingPlan string

@description('The functions name')
param functionsName string

@description('The slot name')
param slotName string

@description('The ID of the User-Assigned Identity to use')
param userAssignedIdentityId string

@description('The application type')
@allowed([
  'isolatedDotnet6'
])
param applicationType string

@description('The server farm ID')
param serverFarmId string

@description('The Azure WebJobs Storage Account name')
param webJobsStorageAccountName string

@description('The App Configuration endpoint')
param appConfigurationEndpoint string = ''

@description('The Application Insights connection string')
param aiConnectionString string = ''

@description('The Service Bus Namespace name')
param serviceBusNamespaceName string = ''

@description('The Key Vault vault URI')
param kvVaultUri string = ''

@description('The application packages URI')
param applicationPackageUri string = ''

@description('The application secret names')
param extraAppSettings object = {}

@description('The deployment location')
param location string

// === VARIABLES ===

var dailyMemoryTimeQuota = pricingPlan == 'Free' ? '10000' : pricingPlan == 'Basic' ? '1000000' : 'ERROR' // in GB.s/d
var linuxFxVersion = applicationType == 'isolatedDotnet6' ? 'DOTNET-ISOLATED|6.0' : 'ERROR'

var formattedExtraAppSettings = json(replace(replace(string(extraAppSettings), '<secret>', '@Microsoft.KeyVault(SecretUri=${kvVaultUri}secrets/'), '</secret>', ')'))
var appSettings = union(formattedExtraAppSettings, {
  'AZURE_FUNCTIONS_ORGANIZATION': referential.organization
  'AZURE_FUNCTIONS_APPLICATION': referential.application
  'AZURE_FUNCTIONS_ENVIRONMENT': referential.environment
  'AZURE_FUNCTIONS_HOST': slotName
  'AZURE_FUNCTIONS_REGION': referential.region
  'FUNCTIONS_EXTENSION_VERSION': applicationType == 'isolatedDotnet6' ? '~4' : 'ERROR'
  'FUNCTIONS_WORKER_RUNTIME': applicationType == 'isolatedDotnet6' ? 'dotnet-isolated' : 'ERROR'
  'AzureWebJobsDisableHomepage': 'true'
  'AzureWebJobsStorage__accountName': webJobsStorageAccountName
}, empty(aiConnectionString) ? {} : {
  'APPLICATIONINSIGHTS_CONNECTION_STRING': aiConnectionString
}, empty(appConfigurationEndpoint) ? {} : {
  'AZURE_FUNCTIONS_APPCONFIG_ENDPOINT': appConfigurationEndpoint
}, empty(kvVaultUri) ? {} : {
  'AZURE_FUNCTIONS_KEYVAULT_VAULT': kvVaultUri
}, empty(serviceBusNamespaceName) ? {} : {
  'AzureWebJobsServiceBus__fullyQualifiedNamespace': '${serviceBusNamespaceName}.servicebus.windows.net'
}, empty(applicationPackageUri) ? {} : {
  'WEBSITE_RUN_FROM_PACKAGE': applicationPackageUri
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
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  tags: referential
  properties: {
    serverFarmId: serverFarmId
    reserved: true
    httpsOnly: true
    dailyMemoryTimeQuota: json(dailyMemoryTimeQuota)
  }

  // Web Configuration
  resource webConfig 'config@2021-03-01' = {
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
  resource appsettingsConfig 'config@2021-03-01' = {
    name: 'appsettings'
    properties: appSettings
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
