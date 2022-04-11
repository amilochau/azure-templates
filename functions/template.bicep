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

@description('The application packages URI')
param applicationPackageUri string = ''

@description('The application secret names')
param applicationSecretNames array = []

@description('The Cosmos DB containers')
param cosmosContainers array = []

@description('The extra deployment slots')
param deploymentSlots array = []

@description('The contribution groups')
param contributionGroups array = []

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

// === EXISTING ===

@description('App Configuration')
resource appConfig 'Microsoft.AppConfiguration/configurationStores@2021-03-01-preview' existing = {
  name: conventions.global.appConfiguration.name
  scope: resourceGroup(conventions.global.appConfiguration.resourceGroupName)
}

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

@description('Key Vault')
module kv '../modules/configuration/key-vault.bicep' = if (!disableKeyVault) {
  name: 'Resource-KeyVault'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
  }
}

@description('Application Insights')
module ai '../modules/monitoring/app-insights.bicep' = if (!disableApplicationInsights) {
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
    applicationType: applicationType
    serverFarmId: asp.outputs.id
    webJobsStorageAccountName: stg.outputs.name
    appConfigurationEndpoint: !disableAppConfiguration ? appConfig.properties.endpoint : ''
    aiConnectionString: !disableApplicationInsights ? ai.outputs.connectionString : ''
    serviceBusNamespaceName: !empty(serviceBusQueues) ? extra_sbn.outputs.name : ''
    kvVaultUri: !disableKeyVault ? kv.outputs.vaultUri : ''
    applicationPackageUri: applicationPackageUri
    applicationSecretNames: !disableKeyVault ? applicationSecretNames : []
  }
}

@description('Functions application')
module fnSlots '../modules/applications/functions/application-slot.bicep' = [for deploymentSlot in deploymentSlots: {
  name: 'Resource-FunctionsSlot-${deploymentSlot.name}'
  params: {
    referential: tags.outputs.referential
    location: location
    pricingPlan: pricingPlan
    userAssignedIdentityId: userAssignedIdentity.outputs.id
    functionsName: fn.outputs.name
    slotName: deploymentSlot.name
    applicationType: applicationType
    serverFarmId: asp.outputs.id
    webJobsStorageAccountName: stg.outputs.name
    appConfigurationEndpoint: !disableAppConfiguration ? appConfig.properties.endpoint : ''
    aiConnectionString: !disableApplicationInsights ? ai.outputs.connectionString : ''
    serviceBusNamespaceName: !empty(serviceBusQueues) ? extra_sbn.outputs.name : ''
    kvVaultUri: !disableKeyVault ? kv.outputs.vaultUri : ''
    applicationPackageUri: applicationPackageUri
  }
}]

@description('Performance tests')
module performanceTest '../modules/monitoring/availability-test.bicep' = if (extendedMonitoring) {
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
module dashboard '../modules/monitoring/web-dashboard.bicep' = if (!disableApplicationInsights) {
  name: 'Resource-Dashboard'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    websiteName: fn.outputs.name
    applicationInsightsName: !disableApplicationInsights ? ai.outputs.name : ''
  }
}

// === AUTHORIZATIONS ===

@description('Functions to App Configuration')
module auth_fn_appConfig '../modules/authorizations/app-configuration-data-reader.bicep' = if (!disableAppConfiguration) {
  name: 'Authorization-Functions-AppConfiguration'
  scope: resourceGroup(conventions.global.appConfiguration.resourceGroupName)
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    appConfigurationName: conventions.global.appConfiguration.name
    roleDescription: 'Functions application should read the configuration from App Configuration'
  }
}

@description('Functions to Key Vault')
module auth_fn_kv '../modules/authorizations/key-vault-secrets-user.bicep' = if (!disableKeyVault) {
  name: 'Authorization-Functions-KeyVault'
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    keyVaultName: kv.outputs.name
    roleDescription: 'Functions application should read the secrets from Key Vault'
  }
}

@description('Functions to Application Insights')
module auth_fn_ai '../modules/authorizations/monitoring-metrics-publisher.bicep' = if (!disableApplicationInsights) {
  name: 'Authorization-Functions-ApplicationInsights'
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    applicationInsightsName: ai.outputs.name
    roleDescription: 'Functions application should send monitoring metrics into Application Insights'
  }
}

@description('Functions to extra Service Bus')
module auth_fn_extra_sbn '../modules/authorizations/service-bus-data-owner.bicep' = if (!empty(serviceBusQueues)) {
  name: 'Authorization-Functions-ServiceBus'
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    serviceBusNamespaceName: !empty(serviceBusQueues) ? extra_sbn.outputs.name : ''
    roleDescription: 'Functions application should read, write and manage the messages from Service Bus'
  }
}

@description('Functions to extra Storage Accounts')
module auth_fn_extra_stg '../modules/authorizations/storage-blob-data.bicep' = [for (account, index) in storageAccounts: if (!empty(storageAccounts)) {
  name: empty(account) ? 'empty' : 'Authorization-Functions-StorageAccount${account.suffix}'
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    storageAccountName: extra_stg[index].outputs.name
    readOnly: account.readOnly
    roleDescription: 'Functions application should read/write the blobs from Storage Account'
  }
}]

@description('Functions to extra Cosmos DB Account')
module auth_fn_extra_cosmos '../modules/authorizations/cosmos-data-contributor.bicep' = if (!empty(cosmosContainers)) {
  name: 'Authorization-Functions-CosmosAccount'
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    cosmosAccountName: !empty(cosmosContainers) ? extra_cosmos.outputs.name : ''
  }
}

@description('Contribution authorization to extra Cosmos DB Accounts')
@batchSize(1) // This is needed because Azure Cosmos DB assignements can't be performed in parallel
module auth_contributors_cosmos '../modules/authorizations/cosmos-data-contributor.bicep' = [for (group, index) in contributionGroups: if (!empty(cosmosContainers) && !empty(contributionGroups)) {
  name: empty(group) ? 'empty' : 'Authorization-ContributionGroup-${index}-CosmosAccount'
  params: {
    principalId: group.id
    cosmosAccountName: !empty(cosmosContainers) ? extra_cosmos.outputs.name : ''
  }
  dependsOn: [
    auth_fn_extra_cosmos // This is needed because Azure Cosmos DB assignements can't be performed in parallel
  ]
}]

@description('Functions to dedicated Storage Account')
module auth_fn_stg  '../modules/authorizations/storage-blob-data.bicep' = {
  name: 'Authorization-Functions-StorageAccount'
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    storageAccountName: stg.outputs.name
    roleDescription: 'Functions application should manage technical data from Storage Account'
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output resourceId string = fn.outputs.id

@description('The Name of the deployed resource')
output resourceName string = fn.outputs.name
