/*
  Deploy a Functions application
  Resources deployed from this template:
    - Functions application
  Required parameters:
    - `referential`
    - `conventions`
    - `pricingPlan`
    - `applicationType`
    - `serverFarmId`
    - `webJobsStorageAccountName`
  Optional parameters:
    - `appConfigurationEndpoint`
    - `aiInstrumentationKey`
    - `serviceBusNamespaceName`
    - `kvVaultUri`
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
    - `principalId`
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
var linuxFxVersion = applicationType == 'isolatedDotnet5' ? 'DOTNET|5.0' : 'ERROR'
var workerRuntime = applicationType == 'isolatedDotnet5' ? 'dotnet-isolated' : 'ERROR'
var extensionVersion = applicationType == 'isolatedDotnet5' ? '~3' : 'ERROR'

// === EXISTING ===

// Storage Account
resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: webJobsStorageAccountName
}

// === RESOURCES ===

// Functions application
resource fn 'Microsoft.Web/sites@2021-01-01' = {
  name: conventions.naming.functionsApplication.name
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
    properties: {
      'APPINSIGHTS_INSTRUMENTATIONKEY': aiInstrumentationKey
      'AZURE_FUNCTIONS_APPCONFIG_ENDPOINT': appConfigurationEndpoint
      'AZURE_FUNCTIONS_ORGANIZATION': referential.organization
      'AZURE_FUNCTIONS_APPLICATION': referential.application
      'AZURE_FUNCTIONS_ENVIRONMENT': referential.environment
      'AZURE_FUNCTIONS_HOST': referential.host
      'AZURE_FUNCTIONS_KEYVAULT_VAULT' : kvVaultUri
      'AzureWebJobsDisableHomepage': 'true' // Disable homepage
      'FUNCTIONS_EXTENSION_VERSION': extensionVersion
      'FUNCTIONS_WORKER_RUNTIME': workerRuntime
      'AzureWebJobsServiceBus__fullyQualifiedNamespace': '${serviceBusNamespaceName}.servicebus.windows.net'
      'AzureWebJobsStorage': 'DefaultEndpointsProtocol=https;AccountName=${webJobsStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${stg.listKeys().keys[0].value}' // Connection to technical storage account - still needed until https://github.com/Azure/functions-action/issues/94 is completed
      'AzureWebJobsStorage__accountName': webJobsStorageAccountName
    }
  }
}

// === OUTPUTS ===

output id string = fn.id
output apiVersion string = fn.apiVersion
output name string = fn.name
output principalId string = fn.identity.principalId
