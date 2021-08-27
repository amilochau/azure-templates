// Deploy infrastructure for Azure Functions application
// Resources deployed from this template:
//   - Functions with its dedicated Service Plan and storage account
//   - Application Insights
//   - Key Vault
//   - Authorizations
//   - Service Bus namespace and queues
//   - Storage accounts and containers
// Required parameters:
//   - `organizationName`
//   - `applicationName`
//   - `environmentName`
//   - `hostName`
//   - `appConfigurationName`
//   - `appConfigurationResourceGroup`
// Optional parameters:
//   - `monitoring`:
//      - `enableApplicationInsights`
//      - `disableLocalAuth`
//      - `dailyCap`
//      - `workspaceName`
//      - `workspaceResourceGroup`
//   - `useKeyVault`
//   - `serviceBusQueues`
//   - `storageAccounts`:
//      - `number`
//      - `containers`
//      - `readOnly`
//      - `daysBeforeDeletion`
// Outputs:
//   [None]

// === PARAMETERS ===

@description('The organization name')
@minLength(3)
@maxLength(3)
param organizationName string

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
@minLength(3)
@maxLength(5)
param hostName string

@description('The App Configuration name')
param appConfigurationName string

@description('The App Configuration resource group')
param appConfigurationResourceGroup string


@description('The Monitoring settings')
param monitoring object = {
  enableApplicationInsights: false
  disableLocalAuth: false
  dailyCap: '1'
}

@description('Use a Key Vault')
param useKeyVault bool = false

@description('The Service Bus Queues to create, that the application manages')
param serviceBusQueues array = []

@description('The Storage Accounts, that the application owns')
param storageAccounts array = []

// === VARIABLES ===

var location = resourceGroup().location

var isLocal = hostName == 'local'
var createServiceBus = !empty(serviceBusQueues)

var hostingPlanName = '${organizationName}-sp-${applicationName}-${hostName}'
var storageAccountName = replace('${organizationName}-stg-${applicationName}-${hostName}', '-','')
var aiName = '${organizationName}-ai-${applicationName}-${hostName}'
var serviceBusNamespaceName = '${organizationName}-bus-${applicationName}-${hostName}'
var keyVaultName = '${organizationName}-kv-${applicationName}-${hostName}'
var functionsAppName = '${organizationName}-fn-${applicationName}-${hostName}'

// === EXISTING ===

// App Configuration
module appConfig '../shared/app-config-existing.bicep' = if (!isLocal) {
  name: 'Existing-AppConfiguration'
  scope: resourceGroup(appConfigurationResourceGroup)
  params: {
    appConfigurationName: appConfigurationName
  }
}

// Log Analytics Workspace
module workspace '../shared/existing/log-analytics-workspace.bicep' = if (!isLocal && monitoring.enableApplicationInsights) {
  name: 'Existing-LogAnalyticsWorkspace'
  scope: resourceGroup(monitoring.workspaceResourceGroup)
  params: {
    workspaceName: monitoring.workspaceName
  }
}

// === RESOURCES ===

// Key Vault
module kv '../shared/key-vault.bicep' = if (useKeyVault) {
  name: keyVaultName
  params: {
    keyVaultName: keyVaultName 
  }
}

// Application Insights
module ai '../shared/app-insights.bicep' = if (monitoring.enableApplicationInsights) {
  name: aiName
  params: {
    aiName: aiName
    disableLocalAuth: monitoring.disableLocalAuth
    dailyCap: monitoring.dailyCap
    workspaceId: workspace.outputs.id
  }
}

// Service Bus
module extra_bus '../shared/service-bus.bicep' = if (createServiceBus) {
  name: serviceBusNamespaceName
  params: {
    serviceBusNamespaceName: serviceBusNamespaceName
    serviceBusQueues: serviceBusQueues
  }
}

// Storage Accounts
module extra_stg '../shared/storage-account.bicep' = [for account in storageAccounts: if (length(storageAccounts) > 0) {
  name: empty(account.number) ? 'dummy' : '${organizationName}-stg-${applicationName}-${account.number}-${hostName}'
  params: {
    storageAccountName: replace('${organizationName}-stg-${applicationName}-${account.number}-${hostName}', '-','')
    blobContainers: account.containers
    daysBeforeDeletion: account.daysBeforeDeletion
  }
}]

// Dedicated Storage for Functions application
module stg '../shared/storage-account.bicep' = if (!isLocal) {
  name: storageAccountName
  params: {
    storageAccountName: storageAccountName
  }
}

// App Service
resource farm 'Microsoft.Web/serverfarms@2021-01-01' = if (!isLocal) {
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

// Functions App
resource fn 'Microsoft.Web/sites@2021-01-01' = if (!isLocal) {
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
      'APPINSIGHTS_INSTRUMENTATIONKEY': monitoring.enableApplicationInsights ? ai.outputs.InstrumentationKey : ''
      'APPLICATIONINSIGHTS_CONNECTION_STRING': monitoring.enableApplicationInsights ? ai.outputs.ConnectionString : ''
      'ASPNETCORE_APPCONFIG_ENDPOINT': appConfig.outputs.endpoint
      'ASPNETCORE_ORGANIZATION': organizationName
      'ASPNETCORE_APPLICATION': applicationName
      'ASPNETCORE_ENVIRONMENT': environmentName
      'ASPNETCORE_HOST': hostName
      'ASPNETCORE_KEYVAULT_VAULT' : useKeyVault ? kv.outputs.vaultUri : ''
      'AzureWebJobsStorage': 'DefaultEndpointsProtocol=https;AccountName=${stg.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${stg.outputs.accountKey}'
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
        value: createServiceBus ? extra_bus.outputs.primaryConnectionString : ''
        type: 'Custom'
      }
    }
  }
}

// Authorizations - Function to App Configuration
module auth_fn_appConfig '../shared/app-config-auth.bicep' = if (!isLocal) {
  name: 'auth-${fn.name}-${appConfigurationName}'
  scope: resourceGroup(appConfigurationResourceGroup)
  params: {
    principalId: fn.identity.principalId
    appConfigurationName: appConfigurationName
  }
}

// Authorizations - Function to Key Vault
module auth_fn_kv '../shared/key-vault-auth.bicep' = if (!isLocal && useKeyVault) {
  name: 'auth-${fn.name}-${keyVaultName}'
  params: {
    principalId: fn.identity.principalId
    keyVaultName: kv.name
  }
}

// Authorizations - Function to Storage Accounts
module auth_fn_stg '../shared/storage-account-auth.bicep' = [for account in storageAccounts: if (!isLocal && length(storageAccounts) > 0) {
  name: empty(account) ? 'dummy' : 'auth-${fn.name}-${replace('${organizationName}-stg-${applicationName}-${account.number}-${hostName}', '-','')}'
  params: {
    principalId: fn.identity.principalId
    storageAccountName: replace('${organizationName}-stg-${applicationName}-${account.number}-${hostName}', '-','')
    readOnly: account.readOnly
  }
}]
