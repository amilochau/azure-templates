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

@description('The Application Insights instrumentation key')
param aiInstrumentationKey string = ''

@description('The Service Bus Namespace name')
param serviceBusNamespaceName string = ''

@description('The Key Vault vault URI')
param kvVaultUri string = ''

@description('The application packages URI')
param applicationPackageUri string = ''

// === VARIABLES ===

var location = resourceGroup().location
var dailyMemoryTimeQuota = pricingPlan == 'Free' ? '10000' : pricingPlan == 'Basic' ? '1000000' : 'ERROR' // in GB.s/d
var linuxFxVersion = applicationType == 'isolatedDotnet6' ? 'DOTNET|6.0' : 'ERROR'

var baseAppSettings = {
  'AZURE_FUNCTIONS_ORGANIZATION': referential.organization
  'AZURE_FUNCTIONS_APPLICATION': referential.application
  'AZURE_FUNCTIONS_ENVIRONMENT': referential.environment
  'AZURE_FUNCTIONS_HOST': referential.host
  'AZURE_FUNCTIONS_REGION': referential.region
  'FUNCTIONS_EXTENSION_VERSION': applicationType == 'isolatedDotnet6' ? '~4' : 'ERROR'
  'FUNCTIONS_WORKER_RUNTIME': applicationType == 'isolatedDotnet6' ? 'dotnet-isolated' : 'ERROR'
  'AzureWebJobsDisableHomepage': 'true'
  'AzureWebJobsStorage__accountName': webJobsStorageAccountName
}
var appSettingsAppInsights = empty(aiInstrumentationKey) ? baseAppSettings : union(baseAppSettings, {
  'APPINSIGHTS_INSTRUMENTATIONKEY': aiInstrumentationKey
})
var appSettingsAppConfig = empty(appConfigurationEndpoint) ? appSettingsAppInsights : union(appSettingsAppInsights, {
  'AZURE_FUNCTIONS_APPCONFIG_ENDPOINT': appConfigurationEndpoint
})
var appSettingsKeyVault = empty(kvVaultUri) ? appSettingsAppConfig : union(appSettingsAppConfig, {
  'AZURE_FUNCTIONS_KEYVAULT_VAULT': kvVaultUri
})
var appSettingsServiceBus = empty(serviceBusNamespaceName) ? appSettingsKeyVault : union(appSettingsKeyVault, {
  'AzureWebJobsServiceBus__fullyQualifiedNamespace': '${serviceBusNamespaceName}.servicebus.windows.net'
})
var appSettingsPackageUri = empty(applicationPackageUri) ? appSettingsServiceBus : union(appSettingsServiceBus, {
  'WEBSITE_RUN_FROM_PACKAGE': applicationPackageUri
  'WEBSITE_MOUNT_ENABLED': '1'
})
// -- Add more conditional unions here if you want to support more settings
var appSettings = appSettingsPackageUri

// === EXISTING ===

@description('Storage Account')
resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: webJobsStorageAccountName
}

// === RESOURCES ===

@description('Functions application')
resource fn 'Microsoft.Web/sites@2021-01-01' = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.functionsApplication}'
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  tags: referential
  properties: {
    serverFarmId: serverFarmId
    reserved: true
    httpsOnly: true
    dailyMemoryTimeQuota: json(dailyMemoryTimeQuota)
  }

  // Web Configuration
  resource webConfig 'config@2021-01-01' = {
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
  resource appsettingsConfig 'config@2021-01-01' = {
    name: 'appsettings'
    properties: appSettings
  }
}

// === OUTPUTS ===

@description('The ID of the deployed Azure Functions')
output id string = fn.id

@description('The API Version of the deployed Azure Functions')
output apiVersion string = fn.apiVersion

@description('The Name of the deployed Azure Functions')
output name string = fn.name

@description('The Principal ID of the deployed Azure Functions')
output principalId string = fn.identity.principalId
