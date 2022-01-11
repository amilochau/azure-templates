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
  'isolatedDotnet5'
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

// === VARIABLES ===

var location = resourceGroup().location
var dailyMemoryTimeQuota = pricingPlan == 'Free' ? '10000' : pricingPlan == 'Basic' ? '1000000' : 'ERROR' // in GB.s/d
var linuxFxVersion = applicationType == 'isolatedDotnet5' ? 'DOTNET|5.0' : applicationType == 'isolatedDotnet6' ? 'DOTNET|6.0' : 'ERROR'

var baseAppSettings = [
  {
    name: 'AZURE_FUNCTIONS_ORGANIZATION'
    value: referential.organization
  }
  {
    name: 'AZURE_FUNCTIONS_APPLICATION'
    value: referential.application
  }
  {
    name: 'AZURE_FUNCTIONS_ENVIRONMENT'
    value: referential.environment
  }
  {
    name: 'AZURE_FUNCTIONS_HOST'
    value: referential.host
  }
  {
    name: 'AZURE_FUNCTIONS_REGION'
    value: referential.region
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: applicationType == 'isolatedDotnet5' ? '~3' : applicationType == 'isolatedDotnet6' ? '~4' : 'ERROR'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: applicationType == 'isolatedDotnet5' || applicationType == 'isolatedDotnet6' ? 'dotnet-isolated' : 'ERROR'
  }
  {
    name: 'AzureWebJobsDisableHomepage'
    value: 'true'
  }
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${webJobsStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${stg.listKeys().keys[0].value}' // Connection to technical storage account - still needed until https://github.com/Azure/functions-action/issues/94 is completed
  }
  {
    name: 'AzureWebJobsStorage__accountName'
    value: webJobsStorageAccountName
  }
]

var appSettingsAppInsights = empty(aiInstrumentationKey) ? baseAppSettings : concat(baseAppSettings, [
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: aiInstrumentationKey
  }
])
var appSettingsAppConfig = empty(appConfigurationEndpoint) ? appSettingsAppInsights : concat(appSettingsAppInsights, [
  {
    name: 'AZURE_FUNCTIONS_APPCONFIG_ENDPOINT'
    value: appConfigurationEndpoint
  }
])
var appSettingsKeyVault = empty(kvVaultUri) ? appSettingsAppConfig : concat(appSettingsAppConfig, [
  {
  name: 'AZURE_FUNCTIONS_KEYVAULT_VAULT'
  value: kvVaultUri
  }
])
var appSettingsServiceBus = empty(serviceBusNamespaceName) ? appSettingsKeyVault : concat(appSettingsKeyVault, [
  {
    name: 'AzureWebJobsServiceBus__fullyQualifiedNamespace'
    value: '${serviceBusNamespaceName}.servicebus.windows.net'
  }
])
// -- Add more conditional unions here if you want to support more settings
var appSettings = appSettingsServiceBus

// === EXISTING ===

@description('Storage Account')
resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: webJobsStorageAccountName
}

// === RESOURCES ===

@description('Functions application')
resource fn 'Microsoft.Web/sites@2021-02-01' = {
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

    // App Configuration
    siteConfig: {
      appSettings: appSettings
    }
  }

  // Web Configuration
  resource webConfig 'config@2021-02-01' = {
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
