/*
  Deploy infrastructure for Azure Functions application
  Resources deployed from this template:
    - Functions with its dedicated Service Plan and storage account
    - Application Insights
    - Key Vault
    - Service Bus namespace and queues
    - Storage accounts, storage containers and CDN
    - Authorizations
  Required parameters:
    - `organizationName`
    - `applicationName`
    - `hostName`
  Optional parameters:
    - `application`: {}
      - `linuxFxVersion`
      - `workerRuntime`
      - `dailyMemoryTimeQuota`
    - `api`: {}
      - `enableApiManagement`
      - `apiManagementName`
      - `apiManagementResourceGroup`
      - `apiManagementKeyVaultName`
      - `apiName`
      - `apiVersion`
      - `subscriptionRequired`
    - `monitoring`: {}
      - `enableApplicationInsights`
      - `disableLocalAuth`
      - `dailyCap`
    - configuration: {}
      - `enableAppConfiguration`
    - secrets: {}
      - `enableKeyVault`
    - `serviceBusQueues`
    - `storageAccounts`: []
      - `number`
      - `comment`
      - `containers`
      - `readOnly`
      - `daysBeforeDeletion`
      - `allowBlobPublicAccess`
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

@description('The API settings')
param api object = {
  enableApiManagement: false
  apiManagementName: ''
  apiManagementResourceGroup: ''
  apiManagementKeyVaultName: ''
  apiName: ''
  subscriptionRequired: true
}

@description('The monitoring settings')
param monitoring object = {
  enableApplicationInsights: false
  disableLocalAuth: false
  dailyCap: '1'
}

@description('The configuration settings')
param configuration object = {
  enableAppConfiguration: false
}

@description('The secrets settings')
param secrets object = {
  enableKeyVault: false
}

@description('The messaging secrets')
param messaging object = {
  enableServiceBus: false
  serviceBusQueues: []
}

@description('The storage secrets')
param storage object = {
  enableStorage: false
  storageAccounts: []
}

// === RESOURCES ===

// Tags
module tags '../modules/resources/tags.bicep' = {
  name: 'Resource-Tags'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    hostName: hostName
  }
}

// Key Vault
module kv '../modules/resources/key-vault/vault.bicep' = if (secrets.enableKeyVault) {
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
    workspaceName: tags.outputs.logAnalyticsWorkspaceName
    workspaceResourceGroupName: tags.outputs.logAnalyticsWorkspaceResourceGroupName
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
    comment: account.comment
    number: account.number
    blobContainers: account.containers
    daysBeforeDeletion: account.daysBeforeDeletion
    allowBlobPublicAccess: account.allowBlobPublicAccess
  }
}]

// Dedicated Storage Account for Functions application
module stg '../modules/resources/storage-account.bicep' = {
  name: 'Resource-StorageAccount'
  params: {
    referential: tags.outputs.referential
    comment: 'Technical storage for Functions application'
  }
}

// Server farm
module farm '../modules/resources/server-farm.bicep' = {
  name: 'Resource-ServerFarm'
  params: {
    referential: tags.outputs.referential
  }
}

// Functions application
module fn '../modules/resources/functions/application.bicep' = {
  name: 'Resource-FunctionsApplication'
  params: {
    referential: tags.outputs.referential
    linuxFxVersion: application.linuxFxVersion
    workerRuntime: application.workerRuntime
    serverFarmId: farm.outputs.id
    webJobsStorageAccountName: stg.outputs.name
    appConfigurationEndpoint: ''
    aiInstrumentationKey: ai.outputs.instrumentationKey
    serviceBusNamespaceName: messaging.enableServiceBus ? extra_sbn.outputs.name : ''
    kvVaultUri: kv.outputs.vaultUri
    dailyMemoryTimeQuota: application.dailyMemoryTimeQuota
  }
}

// API Management backend
module apim_backend '../modules/resources/functions/api-management-backend.bicep' = if (api.enableApiManagement) {
  name: 'Resource-ApiManagementBackend'
  params: {
    referential: tags.outputs.referential
    apiManagementName: api.apiManagementName
    apiManagementResourceGroup: api.apiManagementResourceGroup
    apiManagementKeyVaultName: api.apiManagementKeyVaultName
    functionsAppName: fn.outputs.name
  }
}

// API Management API registration with OpenAPI
module apim_api '../modules/resources/api-management/api-openapi.bicep' = if (api.enableApiManagement) {
  name: 'Resource-ApiManagementApi'
  scope: resourceGroup(api.apiManagementResourceGroup)
  params: {
    referential: tags.outputs.referential
    apiManagementName: api.apiManagementName
    backendId: apim_backend.outputs.backendId
    apiName: api.apiName
    apiVersion: api.apiVersion
    subscriptionRequired: api.subscriptionRequired
  }
}

// === AUTHORIZATIONS ===

// Functions to App Configuration
module auth_fn_appConfig '../modules/authorizations/app-configuration-data-reader.bicep' = if (configuration.enableAppConfiguration) {
  name: 'Authorization-Functions-AppConfiguration'
  scope: resourceGroup(configuration.enableAppConfiguration ? tags.outputs.appConfigurationResourceGroupName : '')
  params: {
    principalId: fn.outputs.principalId
    appConfigurationName: tags.outputs.appConfigurationName
  }
}

// Functions to Key Vault
module auth_fn_kv '../modules/authorizations/key-vault-secrets-user.bicep' = if (secrets.enableKeyVault) {
  name: 'Authorization-Functions-KeyVault'
  params: {
    principalId: fn.outputs.principalId
    keyVaultName: kv.outputs.name
  }
}

// Functions to Application Insights
module auth_fn_ai '../modules/authorizations/monitoring-metrics-publisher.bicep' = if (monitoring.enableApplicationInsights) {
  name: 'Authorization-Functions-ApplicationInsights'
  params: {
    principalId: fn.outputs.principalId
    applicationInsightsName: ai.outputs.name
  }
}

// Functions to extra Service Bus
module auth_fn_extra_sbn '../modules/authorizations/service-bus-data-owner.bicep' = if (messaging.enableServiceBus) {
  name: 'Authorization-Functions-ServiceBus'
  params: {
    principalId: fn.outputs.principalId
    serviceBusNamespaceName: messaging.enableServiceBus ? extra_sbn.outputs.name : ''
  }
}

// Functions to extra Storage Accounts
module auth_fn_extra_stg '../modules/authorizations/storage-blob-data.bicep' = [for (account, index) in storage.storageAccounts: if (storage.enableStorage) {
  name: empty(account) ? 'dummy' : 'Authorization-Functions-StorageAccount${account.number}'
  params: {
    principalId: fn.outputs.principalId
    storageAccountName: extra_stg[index].outputs.name
    readOnly: account.readOnly
  }
}]

// Functions to dedicated Storage Account
module auth_fn_stg  '../modules/authorizations/storage-blob-data.bicep' = {
  name: 'Authorization-Functions-StorageAccount'
  params: {
    principalId: fn.outputs.principalId
    storageAccountName: stg.outputs.name
  }
}
