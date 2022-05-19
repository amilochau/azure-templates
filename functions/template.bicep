/*
  Deploy infrastructure for Azure Functions application, with Application Insights, Key Vault, service bus and storage account resources, authorizations
*/

// === PARAMETERS ===

@description('The organization name')
@minLength(3)
@maxLength(3)
param organizationName string

@description('The application name')
@minLength(2)
@maxLength(11)
param applicationName string

@description('The host name of the deployment stage')
@minLength(3)
@maxLength(5)
param hostName string

@description('The azure-templates version')
@minLength(1)
param templateVersion string


@description('The application type')
@allowed([
  'isolatedDotnet6'
])
param applicationType string

@description('The pricing plan')
@allowed([
  'Free'    // The cheapest plan, can create some small fees
  'Basic'   // Basic use with default limitations
])
param pricingPlan string = 'Free'

@description('The service bus options')
param serviceBusOptions object = {
  queues: []
  authorizeClients: true
}

@description('The storage account options')
param storageAccountsOptions object = {
  accounts: []
  authorizeClients: true
}

@description('The application packages URI')
param applicationPackageUri string = ''

@description('The extra app settings to add')
param extraAppSettings object = {}

@description('The Cosmos DB containers')
param cosmosContainers array = []

@description('The extra deployment slots')
param deploymentSlots array = []

@description('The contribution groups')
param contributionGroups array = []

@description('The static web app to attach')
param staticWebApp object = {
  enabled: false
}

@description('The deployment location')
param location string = resourceGroup().location

// === VARIABLES ===

@description('The region name')
var regionName = json(loadTextContent('../modules/global/regions.json'))[location]

@description('Global & naming conventions')
var conventions = json(replace(replace(replace(replace(loadTextContent('../modules/global/conventions.json'), '%ORGANIZATION%', organizationName), '%APPLICATION%', applicationName), '%HOST%', hostName), '%REGION%', regionName))

@description('Availability tests settings')
var availabilityTestsSettings = json(loadTextContent('../modules/global/organization-based/availability-tests-settings.json'))

@description('Extended monitoring')
var extendedMonitoring = startsWith(hostName, 'prd')

var serviceBusQueues = !contains(serviceBusOptions, 'queues') ? [] : serviceBusOptions.queues
var storageAccounts = !contains(storageAccountsOptions, 'accounts') ? [] : storageAccountsOptions.accounts

// === RESOURCES ===

@description('Resource groupe tags')
module tags '../modules/global/tags.bicep' = {
  name: 'Resource-Tags'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    hostName: hostName
    regionName: regionName
    templateVersion: templateVersion
  }
}

@description('User-Assigned Identity')
module userAssignedIdentity '../modules/authorizations/user-assigned-identity.bicep' = {
  name: 'Resource-UAI'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
  }
}

@description('User-Assigned Identity')
module clients_userAssignedIdentity '../modules/authorizations/user-assigned-identity-clients.bicep' = {
  name: 'Resource-UAI-Clients'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
  }
}

@description('Key Vault')
module kv '../modules/configuration/key-vault.bicep' = {
  name: 'Resource-KeyVault'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
  }
}

@description('Application Insights')
module ai '../modules/monitoring/app-insights.bicep' = {
  name: 'Resource-ApplicationInsights'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    disableLocalAuth: false
    pricingPlan: pricingPlan
  }
}

@description('Service Bus')
module extra_sbn '../modules/communication/service-bus.bicep' = if (!empty(serviceBusQueues)) {
  name: 'Resource-ServiceBus'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    serviceBusQueues: serviceBusQueues
  }
}

@description('Storage Accounts')
module extra_stg '../modules/storage/storage-account.bicep' = [for account in storageAccounts: if (!empty(storageAccounts)) {
  name: empty(account.suffix) ? 'empty' : 'Resource-StorageAccount-${account.suffix}'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    comment: account.comment
    suffix: account.suffix
    blobContainers: account.containers
    daysBeforeDeletion: account.daysBeforeDeletion
    allowBlobPublicAccess: account.allowBlobPublicAccess
  }
}]

@description('Cosmos Accounts')
module extra_cosmos '../modules/storage/cosmos-account.bicep' = if (!empty(cosmosContainers)) {
  name: 'Resource-CosmosAccount'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    cosmosContainers: cosmosContainers
  }
}

@description('Dedicated Storage Account for Functions application')
module stg '../modules/storage/storage-account.bicep' = {
  name: 'Resource-StorageAccount'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    comment: 'Technical storage for Functions application'
    blobContainers: [
      'deployment-packages'
    ]
  }
}

@description('Service Plan')
module asp '../modules/applications/functions/service-plan.bicep' = {
  name: 'Resource-ServerFarm'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
  }
}

@description('Functions application')
module fn '../modules/applications/functions/application.bicep' = {
  name: 'Resource-FunctionsApplication'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    pricingPlan: pricingPlan
    userAssignedIdentityId: userAssignedIdentity.outputs.id
    userAssignedIdentityClientId: userAssignedIdentity.outputs.clientId
    applicationType: applicationType
    serverFarmId: asp.outputs.id
    webJobsStorageAccountName: stg.outputs.name
    aiConnectionString: ai.outputs.connectionString
    serviceBusNamespaceName: !empty(serviceBusQueues) ? extra_sbn.outputs.name : ''
    kvVaultUri: kv.outputs.vaultUri
    applicationPackageUri: applicationPackageUri
    extraAppSettings: extraAppSettings
  }
}

@description('Functions application - slots')
module fnSlots '../modules/applications/functions/application-slot.bicep' = [for deploymentSlot in deploymentSlots: {
  name: 'Resource-FunctionsSlot-${deploymentSlot.name}'
  params: {
    referential: tags.outputs.referential
    location: location
    pricingPlan: pricingPlan
    userAssignedIdentityId: userAssignedIdentity.outputs.id
    userAssignedIdentityClientId: userAssignedIdentity.outputs.clientId
    functionsName: fn.outputs.name
    slotName: deploymentSlot.name
    applicationType: applicationType
    serverFarmId: asp.outputs.id
    webJobsStorageAccountName: stg.outputs.name
    aiConnectionString: ai.outputs.connectionString
    serviceBusNamespaceName: !empty(serviceBusQueues) ? extra_sbn.outputs.name : ''
    kvVaultUri: kv.outputs.vaultUri
    applicationPackageUri: applicationPackageUri
    extraAppSettings: extraAppSettings
  }
}]

@description('Static Web Apps application')
module swa '../modules/applications/static/application.bicep' = if (staticWebApp.enabled) {
  name: 'Resource-StaticWebAppsApplication'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    pricingPlan: pricingPlan
    customDomains: !contains(staticWebApp, 'customDomains') ? [] : staticWebApp.customDomains
  }
}

@description('Performance tests')
module performanceTest '../modules/monitoring/ping-test.bicep' = if (extendedMonitoring) {
  name: 'Resource-PerformanceTest'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    targetUrl: 'https://${fn.outputs.defaultHostName}${availabilityTestsSettings.functions.urlSuffix}'
    applicationInsightsId: ai.outputs.id
    comment: 'Performance tests'
    suffix: 'performance'
    testLocations: availabilityTestsSettings.functions.locations
  }
}

@description('Dashboard')
module dashboard '../modules/monitoring/web-dashboard.bicep' = {
  name: 'Resource-Dashboard'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    websiteName: fn.outputs.name
    applicationInsightsName: ai.outputs.name
  }
}

// === AUTHORIZATIONS ===

@description('Functions to Key Vault')
module auth_fn_kv '../modules/authorizations/subscription/key-vault-secrets-data.bicep' = {
  name: 'Authorization-Functions-KeyVault'
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    keyVaultName: kv.outputs.name
    roleType: 'Reader'
    roleDescription: 'Functions application should read the secrets from Key Vault'
  }
}

@description('Functions to Application Insights')
module auth_fn_ai '../modules/authorizations/subscription/monitoring-data.bicep' = {
  name: 'Authorization-Functions-ApplicationInsights'
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    applicationInsightsName: ai.outputs.name
    roleType: 'Metrics Publisher'
    roleDescription: 'Functions application should send monitoring metrics into Application Insights'
  }
}

@description('Functions to extra Service Bus')
module auth_fn_extra_sbn '../modules/authorizations/subscription/service-bus-data.bicep' = if (!empty(serviceBusQueues)) {
  name: 'Authorization-Functions-ServiceBus'
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    serviceBusNamespaceName: !empty(serviceBusQueues) ? extra_sbn.outputs.name : ''
    roleType: 'Owner'
    roleDescription: 'Functions application should read, write and manage the messages from Service Bus'
  }
}

@description('Functions to extra Storage Accounts')
module auth_fn_extra_stg '../modules/authorizations/subscription/storage-blob-data.bicep' = [for (account, index) in storageAccounts: if (!empty(storageAccounts)) {
  name: empty(account) ? 'empty' : 'Authorization-Functions-StorageAccount${account.suffix}'
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    storageAccountName: extra_stg[index].outputs.name
    roleType: account.readOnly ? 'Reader' : 'Contributor'
    roleDescription: 'Functions application should read/write the blobs from Storage Account'
  }
}]

@description('Functions to extra Cosmos DB Account')
module auth_fn_extra_cosmos '../modules/authorizations/subscription/cosmos-db-data.bicep' = if (!empty(cosmosContainers)) {
  name: 'Authorization-Functions-CosmosAccount'
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    cosmosAccountName: !empty(cosmosContainers) ? extra_cosmos.outputs.name : ''
    roleType: 'Contributor'
  }
}

@description('Contribution authorization to extra Cosmos DB Accounts')
@batchSize(1) // This is needed because Azure Cosmos DB assignements can't be performed in parallel
module auth_contributors_cosmos '../modules/authorizations/subscription/cosmos-db-data.bicep' = [for (group, index) in contributionGroups: if (!empty(cosmosContainers) && !empty(contributionGroups)) {
  name: empty(group) ? 'empty' : 'Authorization-ContributionGroup-${index}-CosmosAccount'
  params: {
    principalId: group.id
    cosmosAccountName: !empty(cosmosContainers) ? extra_cosmos.outputs.name : ''
    roleType: 'Contributor'
  }
  dependsOn: [
    auth_fn_extra_cosmos // This is needed because Azure Cosmos DB assignements can't be performed in parallel
  ]
}]

@description('Functions to dedicated Storage Account')
module auth_fn_stg  '../modules/authorizations/subscription/storage-blob-data.bicep' = {
  name: 'Authorization-Functions-StorageAccount'
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    storageAccountName: stg.outputs.name
    roleType: 'Owner'
    roleDescription: 'Functions application should manage technical data from Storage Account'
  }
}

@description('Clients UAI to extra Service Bus')
module auth_clients_extra_sbn '../modules/authorizations/subscription/service-bus-data.bicep' = if (!empty(serviceBusQueues) && serviceBusOptions.authorizeClients) {
  name: 'Authorization-Clients-ServiceBus'
  params: {
    principalId: clients_userAssignedIdentity.outputs.principalId
    serviceBusNamespaceName: !empty(serviceBusQueues) ? extra_sbn.outputs.name : ''
    roleType: 'Sender'
    roleDescription: 'Functions application clients should write messages to Service Bus'
  }
}

@description('Clients UAI to extra Storage Accounts')
module auth_clients_extra_stg '../modules/authorizations/subscription/storage-blob-data.bicep' = [for (account, index) in storageAccounts: if (!empty(storageAccounts) && storageAccountsOptions.authorizeClients) {
  name: empty(account) ? 'empty' : 'Authorization-Clients-StorageAccount${account.suffix}'
  params: {
    principalId: clients_userAssignedIdentity.outputs.principalId
    storageAccountName: extra_stg[index].outputs.name
    roleType: 'Contributor'
    roleDescription: 'Functions application clients should read & write the blobs from Storage Account'
  }
}]

// === OUTPUTS ===

@description('The ID of the deployed resource')
output resourceId string = fn.outputs.id

@description('The Name of the deployed resource')
output resourceName string = fn.outputs.name
