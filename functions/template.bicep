// Deploy infrastructure for Azure Functions application
// Resources deployed from this template:
//   - Functions with its dedicated Service Plan and storage account
//   - Application Insights
//   - Service Bus
//   - Key Vault
//   - Authorizations
// Required parameters:
//   - `organizationPrefix`
//   - `applicationName`
//   - `environmentName`
//   - `hostName`
//   - `appConfigurationName`
//   - `appConfigurationResourceGroup`
// Optional parameters:
//   - `useApplicationInsights`
//   - `useServiceBus`
//   - `serviceBusQueues`
//   - `useKeyVault`
//   - `useAppConfiguration`
// Outputs:
//   [None]

// === PARAMETERS ===

@description('The organization prefix')
@minLength(3)
@maxLength(3)
param organizationPrefix string

@description('The application name')
@minLength(3)
@maxLength(12)
param applicationName string

@description('The environment name of the deployment stage')
@allowed([
  'Development'
  'Staging'
  'Production'
])
param environmentName string

@description('The host name of the deployment stage')
@allowed([
  'dev'
  'stg'
  'prd'
])
@minLength(3)
@maxLength(3)
param hostName string

@description('The App Configuration name - usefull if useAppConfiguration is set to true')
param appConfigurationName string

@description('The App Configuration resource group - usefull if useAppConfiguration is set to true')
param appConfigurationResourceGroup string


@description('Use Application Insights')
param useApplicationInsights bool = false

@description('Use a Service Bus')
param useServiceBus bool = false

@description('The Service Bus queues')
param serviceBusQueues array = []

@description('Use a Key Vault')
param useKeyVault bool = false

@description('Use an existing App Configuration')
param useAppConfiguration bool = false


// === VARIABLES ===

var location = resourceGroup().location

var hostingPlanName = '${organizationPrefix}-sp-${applicationName}-${hostName}'
var storageAccountName = replace('${organizationPrefix}-stg-${applicationName}-${hostName}', '-','')
var aiName = '${organizationPrefix}-ai-${applicationName}-${hostName}'
var serviceBusNamespaceName = '${organizationPrefix}-bus-${applicationName}-${hostName}'
var keyVaultName = '${organizationPrefix}-kv-${applicationName}-${hostName}'
var functionsAppName = '${organizationPrefix}-fn-${applicationName}-${hostName}'

// === RESOURCES ===

// App Configuration
module appConfig '../shared/app-config-existing.bicep' = if (useAppConfiguration) {
  name: appConfigurationName
  scope: resourceGroup(appConfigurationResourceGroup)
  params: {
    appConfigurationName: appConfigurationName
  }
}

// Key Vault
module kv '../shared/key-vault.bicep' = if (useKeyVault) {
  name: keyVaultName
  params: {
    keyVaultName: keyVaultName 
  }
}

// Application Insights
module ai '../shared/app-insights.bicep' = if (useApplicationInsights) {
  name: aiName
  params: {
    aiName: aiName 
  }
}

// Service Bus
module bus '../shared/service-bus.bicep' = if (useServiceBus) {
  name: serviceBusNamespaceName
  params: {
    serviceBusNamespaceName: serviceBusNamespaceName
    serviceBusQueues: serviceBusQueues
  }
}

// App Service
resource farm 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  kind: 'functionapp'
  properties: {
    reserved: true // Linux App Service
  }
}

// Storage
resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

// Functions App
resource fn 'Microsoft.Web/sites@2021-01-01' = {
  name: functionsAppName
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: farm.id
    reserved: true
    httpsOnly: true
    dailyMemoryTimeQuota: 10000
  }
  identity: {
    type: 'SystemAssigned'
  }

  resource fn_config 'config@2021-01-01' = {
    name: 'web'
    properties: {
      linuxFxVersion: 'DOTNET|3.1'
      localMySqlEnabled: false
      http20Enabled: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
    }
  }

  resource fn_appsettings 'config@2021-01-01' = {
    name: 'appsettings'
    properties: {
      'APPINSIGHTS_INSTRUMENTATIONKEY': useApplicationInsights ? ai.outputs.InstrumentationKey : ''
      'APPLICATIONINSIGHTS_CONNECTION_STRING': useApplicationInsights ? ai.outputs.ConnectionString : ''
      'ASPNETCORE_APPCONFIG_ENDPOINT': useAppConfiguration ? appConfig.outputs.endpoint : ''
      'ASPNETCORE_APPLICATION': applicationName
      'ASPNETCORE_ENVIRONMENT': environmentName
      'ASPNETCORE_HOST': hostName
      'ASPNETCORE_KEYVAULT_VAULT' : useKeyVault ? kv.outputs.vaultUri : ''
      'AzureWebJobsStorage': 'DefaultEndpointsProtocol=https;AccountName=${stg.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(stg.id, stg.apiVersion).keys[0].value}'
      'FUNCTIONS_EXTENSION_VERSION': '~3'
      'FUNCTIONS_WORKER_RUNTIME': 'dotnet'
      'WEBSITE_ENABLE_SYNC_UPDATE_SITE': 'false'
      // TODO 'WEBSITE_RUN_FROM_PACKAGE' : '1' // Not the right value with Linux!
    }
  }

  resource fn_connectionstrings 'config@2021-01-01' = {
    name: 'connectionstrings'
    properties: {
      'ServiceBusConnectionString': {
        value: useServiceBus ? bus.outputs.primaryConnectionString : ''
        type: 'ServiceBus'
      }
    }
  }
}

// Authorizations - Function to App Configuration
module auth_fn_appConfig '../shared/app-config-auth.bicep' = if (useAppConfiguration) {
  name: 'auth-${fn.name}-${appConfigurationName}'
  scope: resourceGroup(appConfigurationResourceGroup)
  params: {
    principalId: fn.identity.principalId
    appConfigurationName: appConfigurationName
  }
}

// Authorizations - Function to Key Vault
module auth_fn_kv '../shared/key-vault-auth.bicep' = if (useKeyVault) {
  name: 'auth-${fn.name}-${keyVaultName}'
  params: {
    principalId: fn.identity.principalId
    keyVaultName: kv.name
  }
}
