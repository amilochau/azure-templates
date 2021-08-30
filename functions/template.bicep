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
// Optional parameters:
//   - `application`: {}
//      - `linuxFxVersion`
//      - `workerRuntime`
//   - `monitoring`: {}
//      - `enableApplicationInsights`
//      - `disableLocalAuth`
//      - `dailyCap`
//      - `workspaceName`
//      - `workspaceResourceGroup`
//   - configuration: {}
//      - `enableAppConfiguration`
//      - `appConfigurationName`
//      - `appConfigurationResourceGroup`
//   - secrets: {}
//      - `enableKeyVault`
//   - `serviceBusQueues`
//   - `storageAccounts`: []
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


@description('The application settings')
param application object = {
  linuxFxVersion: 'DOTNET|5.0'
  workerRuntime: 'dotnet-isolated'
}

@description('The Monitoring settings')
param monitoring object = {
  enableApplicationInsights: false
  disableLocalAuth: false
  dailyCap: '1'
}

@description('The Configuration settings')
param configuration object = {
  enableAppConfiguration: false
  appConfigurationName: ''
  appConfigurationResourceGroup: ''
}

@description('The Secrets settings')
param secrets object = {
  enableKeyVault: false
}

@description('The Messaging secrets')
param messaging object = {
  enableServiceBus: false
  serviceBusQueues: []
}

@description('The Storage secrets')
param storage object = {
  enableStorage: false
  storageAccounts: []
}

// === VARIABLES ===

var isLocal = hostName == 'local'

// === EXISTING ===

// App Configuration
module appConfig '../shared/existing/app-configuration.bicep' = if (configuration.enableAppConfiguration) {
  name: 'Existing-AppConfiguration'
  scope: resourceGroup(configuration.appConfigurationResourceGroup)
  params: {
    appConfigurationName: configuration.appConfigurationName
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

// Tags
module tags '../shared/resources/tags.bicep' = {
  name: 'Resource-Tags'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    environmentName: environmentName
    hostName: hostName
  }
}

// Key Vault
module kv '../shared/resources/key-vault.bicep' = if (secrets.enableKeyVault) {
  name: 'Resource-KeyVault'
  params: {
    referential: {
      referential: tags.outputs.referential
    }
  }
}

// Application Insights
module ai '../shared/resources/app-insights.bicep' = if (monitoring.enableApplicationInsights) {
  name: 'Resource-ApplicationInsights'
  params: {
    referential: tags.outputs.referential
    disableLocalAuth: monitoring.disableLocalAuth
    dailyCap: monitoring.dailyCap
    workspaceId: workspace.outputs.id
  }
}

// Service Bus
module extra_bus '../shared/resources/service-bus.bicep' = if (messaging.enableServiceBus) {
  name: 'Resource-ServiceBus'
  params: {
    referential: tags.outputs.referential
    serviceBusQueues: messaging.serviceBusQueues
  }
}

// Storage Accounts
module extra_stg '../shared/resources/storage-account.bicep' = [for account in storage.storageAccounts: if (storage.enableStorage) {
  name: empty(account.number) ? 'dummy' : 'Resource-StorageAccount-${account.number}'
  params: {
    referential: tags.outputs.referential
    number: account.number
    blobContainers: account.containers
    daysBeforeDeletion: account.daysBeforeDeletion
  }
}]

// Dedicated Storage for Functions application
module stg '../shared/resources/storage-account.bicep' = if (!isLocal) {
  name: 'Resource-StorageAccount'
  params: {
    referential: {
      referential: tags.outputs.referential
    }
  }
}

// Server farm
module farm '../shared/resources/server-farm.bicep' = if (!isLocal) {
  name: 'Resource-ServerFarm'
  params: {
    referential: {
      referential: tags.outputs.referential
    }
  }
}

// Website (Functions)
module fn '../shared/resources/website-functions.bicep' = if (!isLocal) {
  name: 'Resource-WebsiteFunctions'
  params: {
    referential: tags.outputs.referential
    linuxFxVersion: application.linuxFxVersion
    workerRuntime: application.workerRuntime
    serverFarmId: farm.outputs.id
    webJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${stg.outputs.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${stg.outputs.accountKey}'
    appConfigurationEndpoint: appConfig.outputs.endpoint
    aiInstrumentationKey: ai.outputs.InstrumentationKey
    // aiConnectionString: ai.outputs.ConnectionString // TODO Not used anymore, keep it until stable major version
    // serviceBusConnectionString: extra_bus.outputs.primaryConnectionString // TODO Not used anymore, keep it until stable major version
    serviceBusNamespaceName: extra_bus.outputs.name
    kvVaultUri: kv.outputs.vaultUri
  }
}

// === AUTHORIZATIONS ===

// Functions to App Configuration
module auth_fn_appConfig '../shared/authorizations/app-configuration-data-reader.bicep' = if (!isLocal && configuration.enableAppConfiguration) {
  name: 'Authorization-Functions-AppConfiguration'
  scope: resourceGroup(configuration.appConfigurationResourceGroup)
  params: {
    principalId: fn.outputs.principalId
    appConfigurationName: configuration.appConfigurationName
  }
}

// Functions to Key Vault
module auth_fn_kv '../shared/authorizations/key-vault-secrets-user.bicep' = if (!isLocal && secrets.enableKeyVault) {
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

// Functions to extra Service Bus
module auth_fn_extra_bus '../shared/authorizations/service-bus-data-owner.bicep' = if (!isLocal && messaging.enableServiceBus) {
  name: 'Authorization-Functions-ServiceBus'
  params: {
    principalId: fn.outputs.principalId
    serviceBusNamespaceName: extra_bus.outputs.name
  }
}

// Functions to extra Storage Accounts
module auth_fn_extra_stg '../shared/authorizations/storage-blob-data.bicep' = [for (account, index) in storage.storageAccounts: if (!isLocal && storage.enableStorage) {
  name: empty(account) ? 'dummy' : 'Authorization-Functions-StorageAccount${account.number}'
  params: {
    principalId: fn.outputs.principalId
    storageAccountName: replace('${extra_stg[index].outputs.name}', '-','')
    readOnly: account.readOnly
  }
}]
