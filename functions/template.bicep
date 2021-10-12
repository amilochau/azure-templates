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
    - `applicationType`
  Optional parameters:
    - `pricingPlan`
    - `api`: {}
      - `enableApiManagement`
      - `apiVersion`
      - `subscriptionRequired`
    - `disableApplicationInsights`
    - `disableAppConfiguration`
    - `disableKeyVault`
    - `serviceBusQueues`: []
    - `storageAccounts`: []
      - `number`
      - `comment`
      - `containers`: []
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


@description('The pricing plan')
@allowed([
  'Free'    // The cheapest plan, can create some small fees
  'Basic'   // Basic use with default limitations
])
param pricingPlan string = 'Free'

@description('The application type')
@allowed([
  'isolatedDotnet5'
])
param applicationType string

@description('The API settings')
param api object = {
  enableApiManagement: false
  subscriptionRequired: true
}

@description('Whether to disable the Application Insights')
param disableApplicationInsights bool = false

@description('Whether to disable the App Configuration')
param disableAppConfiguration bool = false

@description('Whether to disable the Key Vault')
param disableKeyVault bool = false

@description('The service bus queues')
param serviceBusQueues array = []

@description('The storage accounts')
param storageAccounts array = []

// === VARIABLES ===

var conventions = json(replace(replace(replace(loadTextContent('../modules/global/conventions.json'), '%ORGANIZATION%', organizationName), '%APPLICATION%', applicationName), '%HOST%', hostName))

// === RESOURCES ===

// Tags
module tags '../modules/global/tags.bicep' = {
  name: 'Resource-Tags'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    hostName: hostName
  }
}

// Key Vault
module kv '../modules/configuration/key-vault.bicep' = if (!disableKeyVault) {
  name: 'Resource-KeyVault'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
  }
}

// Application Insights
module ai '../modules/monitoring/app-insights.bicep' = if (!disableApplicationInsights) {
  name: 'Resource-ApplicationInsights'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    disableLocalAuth: false
    pricingPlan: pricingPlan
  }
}

// Service Bus
module extra_sbn '../modules/communication/service-bus.bicep' = if (!empty(serviceBusQueues)) {
  name: 'Resource-ServiceBus'
  params: {
    referential: tags.outputs.referential
    serviceBusQueues: serviceBusQueues
  }
}

// Storage Accounts
module extra_stg '../modules/storage/storage-account.bicep' = [for account in storageAccounts: if (!empty(storageAccounts)) {
  name: empty(account.number) ? 'empty' : 'Resource-StorageAccount-${account.number}'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    comment: account.comment
    number: account.number
    blobContainers: account.containers
    daysBeforeDeletion: account.daysBeforeDeletion
    allowBlobPublicAccess: account.allowBlobPublicAccess
  }
}]

// Dedicated Storage Account for Functions application
module stg '../modules/storage/storage-account.bicep' = {
  name: 'Resource-StorageAccount'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    comment: 'Technical storage for Functions application'
  }
}

// Service Plan
module asp '../modules/functions/service-plan.bicep' = {
  name: 'Resource-ServerFarm'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
  }
}

// Functions application
module fn '../modules/functions/application.bicep' = {
  name: 'Resource-FunctionsApplication'
  params: {
    referential: tags.outputs.referential
    pricingPlan: pricingPlan
    applicationType: applicationType
    serverFarmId: asp.outputs.id
    webJobsStorageAccountName: stg.outputs.name
    appConfigurationEndpoint: ''
    aiInstrumentationKey: !disableApplicationInsights ? ai.outputs.instrumentationKey : ''
    serviceBusNamespaceName: !empty(serviceBusQueues) ? extra_sbn.outputs.name : ''
    kvVaultUri: !disableKeyVault ? kv.outputs.vaultUri : ''
  }
}

// API Management backend
module apim_backend '../modules/functions/api-management-backend.bicep' = if (api.enableApiManagement) {
  name: 'Resource-ApiManagementBackend'
  params: {
    conventions: conventions
    functionsAppName: fn.outputs.name
  }
}

// API Management API registration with OpenAPI
module apim_api '../modules/api-management/api-openapi.bicep' = if (api.enableApiManagement) {
  name: 'Resource-ApiManagementApi'
  scope: resourceGroup(conventions.global.apiManagementResourceGroupName)
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    backendId: apim_backend.outputs.backendId
    apiVersion: api.apiVersion
    subscriptionRequired: api.subscriptionRequired
  }
}

// === AUTHORIZATIONS ===

// Functions to App Configuration
module auth_fn_appConfig '../modules/authorizations/app-configuration-data-reader.bicep' = if (!disableAppConfiguration) {
  name: 'Authorization-Functions-AppConfiguration'
  scope: resourceGroup(conventions.global.appConfigurationResourceGroupName)
  params: {
    principalId: fn.outputs.principalId
    appConfigurationName: conventions.global.appConfiguration.name
  }
}

// Functions to Key Vault
module auth_fn_kv '../modules/authorizations/key-vault-secrets-user.bicep' = if (!disableKeyVault) {
  name: 'Authorization-Functions-KeyVault'
  params: {
    principalId: fn.outputs.principalId
    keyVaultName: kv.outputs.name
  }
}

// Functions to Application Insights
module auth_fn_ai '../modules/authorizations/monitoring-metrics-publisher.bicep' = if (!disableApplicationInsights) {
  name: 'Authorization-Functions-ApplicationInsights'
  params: {
    principalId: fn.outputs.principalId
    applicationInsightsName: ai.outputs.name
  }
}

// Functions to extra Service Bus
module auth_fn_extra_sbn '../modules/authorizations/service-bus-data-owner.bicep' = if (!empty(serviceBusQueues)) {
  name: 'Authorization-Functions-ServiceBus'
  params: {
    principalId: fn.outputs.principalId
    serviceBusNamespaceName: !empty(serviceBusQueues) ? extra_sbn.outputs.name : ''
  }
}

// Functions to extra Storage Accounts
module auth_fn_extra_stg '../modules/authorizations/storage-blob-data.bicep' = [for (account, index) in storageAccounts: if (!empty(storageAccounts)) {
  name: empty(account) ? 'empty' : 'Authorization-Functions-StorageAccount${account.number}'
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
