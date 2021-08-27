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

var isLocal = hostName == 'local'
var createServiceBus = !empty(serviceBusQueues)

// === EXISTING ===

// App Configuration
module appConfig '../shared/existing/app-configuration.bicep' = {
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
module kv '../shared/resources/key-vault.bicep' = if (useKeyVault) {
  name: 'Resource-KeyVault'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    environmentName: environmentName
    hostName: hostName
  }
}

// Application Insights
module ai '../shared/resources/app-insights.bicep' = if (monitoring.enableApplicationInsights) {
  name: 'Resource-ApplicationInsights'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    environmentName: environmentName
    hostName: hostName
    disableLocalAuth: monitoring.disableLocalAuth
    dailyCap: monitoring.dailyCap
    workspaceId: workspace.outputs.id
  }
}

// Service Bus
module extra_bus '../shared/resources/service-bus.bicep' = if (createServiceBus) {
  name: 'Resource-ServiceBus'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    environmentName: environmentName
    hostName: hostName
    serviceBusQueues: serviceBusQueues
  }
}

// Storage Accounts
module extra_stg '../shared/resources/storage-account.bicep' = [for account in storageAccounts: if (length(storageAccounts) > 0) {
  name: empty(account.number) ? 'dummy' : 'Resource-StorageAccount-${account.number}'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    environmentName: environmentName
    hostName: hostName
    number: account.number
    blobContainers: account.containers
    daysBeforeDeletion: account.daysBeforeDeletion
  }
}]

// Dedicated Storage for Functions application
module stg '../shared/resources/storage-account.bicep' = if (!isLocal) {
  name: 'Resource-StorageAccount'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    environmentName: environmentName
    hostName: hostName
  }
}

// Server farm
module farm '../shared/resources/server-farm.bicep' = if (!isLocal) {
  name: 'Resource-ServerFarm'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    environmentName: environmentName
    hostName: hostName
  }
}

// Website (Functions)
module fn '../shared/resources/website-functions.bicep' = if (!isLocal) {
  name: 'Resource-WebsiteFunctions'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    environmentName: environmentName
    hostName: hostName
    serverFarmId: farm.outputs.id
    webJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${stg.outputs.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${stg.outputs.accountKey}'
    appConfigurationEndpoint: appConfig.outputs.endpoint
    aiInstrumentationKey: ai.outputs.InstrumentationKey
    aiConnectionString: ai.outputs.ConnectionString
    serviceBusConnectionString: extra_bus.outputs.primaryConnectionString
    kvVaultUri: kv.outputs.vaultUri
  }
}

// === AUTHORIZATIONS ===

// Functions to App Configuration
module auth_fn_appConfig '../shared/authorizations/app-configuration-data-reader.bicep' = if (!isLocal) {
  name: 'Authorization-Functions-AppConfiguration'
  scope: resourceGroup(appConfigurationResourceGroup)
  params: {
    principalId: fn.outputs.principalId
    appConfigurationName: appConfigurationName
  }
}

// Functions to Key Vault
module auth_fn_kv '../shared/authorizations/key-vault-secrets-user.bicep' = if (!isLocal && useKeyVault) {
  name: 'Authorization-Functions-KeyVault'
  params: {
    principalId: fn.outputs.principalId
    keyVaultName: kv.outputs.name
  }
}

// Functions to Application Insights
module auth_fn_ai '../shared/authorizations/monitoring-metrics-publisher.bicep' = if (!isLocal && monitoring.enableApplicationInsights) {
  name: 'Authorization-Functions-ApplicationInsights'
  params: {
    principalId: fn.outputs.principalId
    applicationInsightsName: ai.outputs.name
  }
}

// Functions to Storage Accounts
module auth_fn_stg '../shared/authorizations/storage-blob-data.bicep' = [for (account, index) in storageAccounts: if (!isLocal && length(storageAccounts) > 0) {
  name: empty(account) ? 'dummy' : 'Authorization-Functions-StorageAccount${account.number}'
  params: {
    principalId: fn.outputs.principalId
    storageAccountName: replace('${extra_stg[index].outputs.name}', '-','')
    readOnly: account.readOnly
  }
}]
