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

@description('The application secret names')
param applicationSecretNames array = []

@description('The deployment location')
param location string

// === VARIABLES ===

var dailyMemoryTimeQuota = pricingPlan == 'Free' ? '10000' : pricingPlan == 'Basic' ? '1000000' : 'ERROR' // in GB.s/d
var linuxFxVersion = applicationType == 'isolatedDotnet6' ? 'DOTNET-ISOLATED|6.0' : 'ERROR'

var secrets = [for secretName in applicationSecretNames: {
  name: secretName
  value: '@Microsoft.KeyVault(SecretUri=${kvVaultUri}secrets/${secretName}/)'
}]
var appSettings = concat([
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
    value: applicationType == 'isolatedDotnet6' ? '~4' : 'ERROR'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: applicationType == 'isolatedDotnet6' ? 'dotnet-isolated' : 'ERROR'
  }
  {
    name: 'AzureWebJobsDisableHomepage'
    value: 'true'
  }
  {
    name: 'AzureWebJobsStorage__accountName'
    value: webJobsStorageAccountName
  }
  empty(aiInstrumentationKey) ? {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: aiInstrumentationKey
  } : []
  empty(appConfigurationEndpoint) ? {
    name: 'AZURE_FUNCTIONS_APPCONFIG_ENDPOINT'
    value: appConfigurationEndpoint
  } : []
  empty(kvVaultUri) ? {
    name: 'AZURE_FUNCTIONS_KEYVAULT_VAULT'
    value: kvVaultUri
  } : []
  empty(serviceBusNamespaceName) ? {
    name: 'AzureWebJobsServiceBus__fullyQualifiedNamespace'
    value: '${serviceBusNamespaceName}.servicebus.windows.net'
  } : []
  empty(applicationPackageUri) ? {
    name: 'WEBSITE_RUN_FROM_PACKAGE'
    value: applicationPackageUri
  } : []
  empty(applicationSecretNames) ? secrets : []
])

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
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      localMySqlEnabled: false
      http20Enabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: appSettings
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

@description('The default host name if the deployed Azure Functions')
output defaultHostName string = fn.properties.defaultHostName
