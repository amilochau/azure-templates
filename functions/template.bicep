/*
  Deploy infrastructure for Azure Functions application
  Resources deployed from this template:
    - Functions with its dedicated Service Plan and storage account
    - Application Insights
    - Key Vault
    - Service Bus namespace and queues
    - Storage accounts and containers
    - Authorizations
  Required parameters:
    - `organizationName`
    - `applicationName`
    - `environmentName`
    - `hostName`
  Optional parameters:
    - `application`: {}
      - `linuxFxVersion`
      - `workerRuntime`
      - `dailyMemoryTimeQuota`
    - `monitoring`: {}
      - `enableApplicationInsights`
      - `disableLocalAuth`
      - `dailyCap`
      - `workspaceName`
      - `workspaceResourceGroup`
    - configuration: {}
      - `enableAppConfiguration`
      - `appConfigurationName`
      - `appConfigurationResourceGroup`
    - secrets: {}
      - `enableKeyVault`
    - `serviceBusQueues`
    - `storageAccounts`: []
      - `number`
      - `containers`
      - `readOnly`
      - `daysBeforeDeletion`
  Outputs:
    [None]
*/

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
  dailyMemoryTimeQuota: '10000'
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
module appConfig '../modules/existing/app-configuration.bicep' = if (configuration.enableAppConfiguration) {
  name: 'Existing-AppConfiguration'
  params: {
    appConfigurationName: configuration.appConfigurationName
    appConfigurationResourceGroup: configuration.appConfigurationResourceGroup
  }
}

// Log Analytics Workspace
module workspace '../modules/existing/log-analytics-workspace.bicep' = if (!isLocal && monitoring.enableApplicationInsights) {
  name: 'Existing-LogAnalyticsWorkspace'
  params: {
    workspaceName: monitoring.workspaceName
    workspaceResourceGroup: monitoring.workspaceResourceGroup
  }
}

// === RESOURCES ===

// Tags
module tags '../modules/resources/tags.bicep' = {
  name: 'Resource-Tags'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    environmentName: environmentName
    hostName: hostName
  }
}

// Key Vault
module kv '../modules/resources/key-vault.bicep' = if (secrets.enableKeyVault) {
  name: 'Resource-KeyVault'
  params: {
    referential: tags.outputs.referential
  }
}

// Application Insights
module ai '../modules/resources/app-insights.bicep' = if (monitoring.enableApplicationInsights) {
  name: 'Resource-ApplicationInsights'
  params: {
    referential: tags.outputs.referential
    disableLocalAuth: monitoring.disableLocalAuth
    dailyCap: monitoring.dailyCap
    workspaceId: workspace.outputs.id
  }
}

// Service Bus
module extra_sbn '../modules/resources/service-bus.bicep' = if (messaging.enableServiceBus) {
  name: 'Resource-ServiceBus'
  params: {
    referential: tags.outputs.referential
    serviceBusQueues: messaging.serviceBusQueues
  }
}

// Storage Accounts
module extra_stg '../modules/resources/storage-account.bicep' = [for account in storage.storageAccounts: if (storage.enableStorage) {
  name: empty(account.number) ? 'dummy' : 'Resource-StorageAccount-${account.number}'
  params: {
    referential: tags.outputs.referential
    number: account.number
    blobContainers: account.containers
    daysBeforeDeletion: account.daysBeforeDeletion
  }
}]

// Dedicated Storage Account for Functions application
module stg '../modules/resources/storage-account.bicep' = if (!isLocal) {
  name: 'Resource-StorageAccount'
  params: {
    referential: tags.outputs.referential
  }
}

// Server farm
module farm '../modules/resources/server-farm.bicep' = if (!isLocal) {
  name: 'Resource-ServerFarm'
  params: {
    referential: tags.outputs.referential
  }
}

// Website (Functions)
module fn '../modules/resources/website-functions.bicep' = if (!isLocal) {
  name: 'Resource-WebsiteFunctions'
  params: {
    referential: tags.outputs.referential
    linuxFxVersion: application.linuxFxVersion
    workerRuntime: application.workerRuntime
    serverFarmId: farm.outputs.id
    webJobsStorageAccountName: stg.outputs.name
    appConfigurationEndpoint: appConfig.outputs.endpoint
    aiInstrumentationKey: ai.outputs.instrumentationKey
    serviceBusNamespaceName: messaging.enableServiceBus ? extra_sbn.outputs.name : ''
    kvVaultUri: kv.outputs.vaultUri
    dailyMemoryTimeQuota: application.dailyMemoryTimeQuota
  }
}

// === AUTHORIZATIONS ===

// Functions to App Configuration
module auth_fn_appConfig '../modules/authorizations/app-configuration-data-reader.bicep' = if (!isLocal && configuration.enableAppConfiguration) {
  name: 'Authorization-Functions-AppConfiguration'
  scope: resourceGroup(configuration.enabled ? configuration.appConfigurationResourceGroup : '')
  params: {
    principalId: fn.outputs.principalId
    appConfigurationName: configuration.appConfigurationName
  }
}

// Functions to Key Vault
module auth_fn_kv '../modules/authorizations/key-vault-secrets-user.bicep' = if (!isLocal && secrets.enableKeyVault) {
  name: 'Authorization-Functions-KeyVault'
  params: {
    principalId: fn.outputs.principalId
    keyVaultName: kv.outputs.name
  }
}

// Functions to Application Insights
module auth_fn_ai '../modules/authorizations/monitoring-metrics-publisher.bicep' = if (!isLocal && monitoring.enableApplicationInsights) {
  name: 'Authorization-Functions-ApplicationInsights'
  params: {
    principalId: fn.outputs.principalId
    applicationInsightsName: ai.outputs.name
  }
}

// Functions to extra Service Bus
module auth_fn_extra_sbn '../modules/authorizations/service-bus-data-owner.bicep' = if (!isLocal && messaging.enableServiceBus) {
  name: 'Authorization-Functions-ServiceBus'
  params: {
    principalId: fn.outputs.principalId
    serviceBusNamespaceName: messaging.enableServiceBus ? extra_sbn.outputs.name : ''
  }
}

// Functions to extra Storage Accounts
module auth_fn_extra_stg '../modules/authorizations/storage-blob-data.bicep' = [for (account, index) in storage.storageAccounts: if (!isLocal && storage.enableStorage) {
  name: empty(account) ? 'dummy' : 'Authorization-Functions-StorageAccount${account.number}'
  params: {
    principalId: fn.outputs.principalId
    storageAccountName: extra_stg[index].outputs.name
    readOnly: account.readOnly
  }
}]

// Functions to dedicated Storage Account
module auth_fn_stg  '../modules/authorizations/storage-blob-data.bicep' = if (!isLocal) {
  name: 'Authorization-Functions-StorageAccount'
  params: {
    principalId: fn.outputs.principalId
    storageAccountName: stg.outputs.name
  }
}
