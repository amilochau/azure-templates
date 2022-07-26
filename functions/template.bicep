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


@description('The pricing plan')
@allowed([
  'Free'    // The cheapest plan, can create some small fees
  'Basic'   // Basic use with default limitations
])
param pricingPlan string = 'Free'

@description('''
The service bus options:
- **enabled**: bool
- *queues*: string[]
- *authorizeClients*: bool
''')
param serviceBusOptions object = {
  enabled: false
}

@description('''
The storage accounts options:
- **enabled**: bool
- **accounts**: array
  - **suffix**: string
  - **comment**: string
  - **containers**: string[]
  - *daysBeforeDeletion*: int
  - *allowBlobPublicAccess*: bool
  - *authorizeClients*: bool
  - *readOnly*: bool
''')
param storageAccountsOptions object = {
  enabled: false
}

@description('''
The Cosmos account options:
- **enabled**: bool
- **containers**: array
  - **name**: string
  - **partitionKey**: string
  - *uniqueKeys*: string[]
  - *compositeIndexes*: array of array
    - **path**: string
    - **order**: string
  - *includedPaths*: array
    - **path**: string
  - *excludedPaths*: array
    - **path**: string
  - *defaultTtl*: int
''')
param cosmosAccountOptions object = {
  enabled: false
}

@description('''
The Static Web app options:
- **enabled**: bool
- *customDomains*: string[]
''')
param staticWebAppOptions object = {
  enabled: false
}

@description('''
The Functions app options:
- **stack**: string
- *extraAppSettings*: dictionary
- *extraIdentities*: dictionary
- *extraSlots*: array
  - **name**
- *openId*:
  - **clientSecretKey**
  - **endpoint**
  - **apiClientId**
  - *skipAuthentication*
  - *anonymousEndpoints*
''')
param functionsAppOptions object

@description('The application package URI')
param applicationPackageUri string = ''

@description('The contribution groups')
param contributionGroups array = []

@description('The deployment location')
param location string = resourceGroup().location

// === VARIABLES ===

@description('The region name')
var regionName = loadJsonContent('../modules/global/regions.json')[location].name

@description('Global & naming conventions')
var conventions = json(replace(replace(replace(replace(loadTextContent('../modules/global/conventions.json'), '%ORGANIZATION%', organizationName), '%APPLICATION%', applicationName), '%HOST%', hostName), '%REGION%', regionName))

@description('Web tests settings')
var webTestsSettings = loadJsonContent('../modules/global/organization-based/web-tests-settings.json', 'functions')

@description('Extended monitoring')
var extendedMonitoring = startsWith(hostName, 'prd')

var storageAccounts = storageAccountsOptions.enabled ? storageAccountsOptions.accounts : []

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

@description('User-Assigned Identity for application itself')
module userAssignedIdentity_application '../modules/authorizations/user-assigned-identity.bicep' = {
  name: 'Resource-UAI-Application'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    type: 'application'
    location: location
  }
}

@description('User-Assigned Identity for clients')
module userAssignedIdentity_clients '../modules/authorizations/user-assigned-identity.bicep' = {
  name: 'Resource-UAI-Clients'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    type: 'clients'
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
module extra_sbn '../modules/communication/service-bus.bicep' = if (serviceBusOptions.enabled) {
  name: 'Resource-ServiceBus'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    serviceBusOptions: serviceBusOptions
  }
}

@description('Storage Accounts')
module extra_stg '../modules/storage/storage-account.bicep' = [for storageAccountOptions in storageAccounts: if (storageAccountsOptions.enabled) {
  name: empty(storageAccountOptions) ? 'empty' : 'Resource-StorageAccount-${storageAccountOptions.suffix}'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    storageAccountOptions: storageAccountOptions
  }
}]

@description('Cosmos Account')
module extra_cosmos '../modules/storage/cosmos-account.bicep' = if (cosmosAccountOptions.enabled) {
  name: 'Resource-CosmosAccount'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    pricingPlan: pricingPlan
    location: location
    cosmosAccountOptions: cosmosAccountOptions
  }
}

@description('Dedicated Storage Account for Functions application')
module stg '../modules/storage/storage-account.bicep' = {
  name: 'Resource-StorageAccount'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    storageAccountOptions: {
      comment: 'Technical storage for Functions application'
      containers: [
        'deployment-packages'
      ]
    }
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
    userAssignedIdentityId: userAssignedIdentity_application.outputs.id
    userAssignedIdentityClientId: userAssignedIdentity_application.outputs.clientId
    serverFarmId: asp.outputs.id
    webJobsStorageAccountName: stg.outputs.name
    aiConnectionString: ai.outputs.connectionString
    serviceBusNamespaceName: serviceBusOptions.enabled ? extra_sbn.outputs.name : ''
    kvVaultUri: kv.outputs.vaultUri
    functionsAppOptions: functionsAppOptions
    applicationPackageUri: applicationPackageUri
  }
}

@description('Static Web Apps application')
module swa '../modules/applications/static/application.bicep' = if (staticWebAppOptions.enabled) {
  name: 'Resource-StaticWebAppsApplication'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    pricingPlan: pricingPlan
    staticWebAppOptions: staticWebAppOptions
  }
}

@description('Web tests')
module webTest '../modules/monitoring/web-test-ping.bicep' = if (extendedMonitoring) {
  name: 'Resource-WebTest'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    targetUrl: 'https://${fn.outputs.defaultHostName}${webTestsSettings.urlSuffix}'
    applicationInsightsId: ai.outputs.id
    comment: 'Performance tests'
    suffix: 'performance'
    testLocations: webTestsSettings.locations
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
    principalId: userAssignedIdentity_application.outputs.principalId
    keyVaultName: kv.outputs.name
    roleType: 'Reader'
    roleDescription: 'Functions application should read the secrets from Key Vault'
  }
}

@description('Functions to Application Insights')
module auth_fn_ai '../modules/authorizations/subscription/monitoring-data.bicep' = {
  name: 'Authorization-Functions-ApplicationInsights'
  params: {
    principalId: userAssignedIdentity_application.outputs.principalId
    applicationInsightsName: ai.outputs.name
    roleType: 'Metrics Publisher'
    roleDescription: 'Functions application should send monitoring metrics into Application Insights'
  }
}

@description('Functions to extra Service Bus')
module auth_fn_extra_sbn '../modules/authorizations/subscription/service-bus-data.bicep' = if (serviceBusOptions.enabled) {
  name: 'Authorization-Functions-ServiceBus'
  params: {
    principalId: userAssignedIdentity_application.outputs.principalId
    serviceBusNamespaceName: serviceBusOptions.enabled ? extra_sbn.outputs.name : ''
    roleType: 'Owner'
    roleDescription: 'Functions application should read, write and manage the messages from Service Bus'
  }
}

@description('Functions to extra Storage Accounts')
module auth_fn_extra_stg '../modules/authorizations/subscription/storage-blob-data.bicep' = [for (storageAccountOptions, index) in storageAccounts: if (storageAccountsOptions.enabled) {
  name: empty(storageAccountOptions) ? 'empty' : 'Authorization-Functions-StorageAccount${storageAccountOptions.suffix}'
  params: {
    principalId: userAssignedIdentity_application.outputs.principalId
    storageAccountName: extra_stg[index].outputs.name
    roleType: contains(storageAccountOptions, 'readOnly') && storageAccountOptions.readOnly ? 'Reader' : 'Contributor'
    roleDescription: 'Functions application should read/write the blobs from Storage Account'
  }
}]

@description('Functions to extra Cosmos DB Account')
module auth_fn_extra_cosmos '../modules/authorizations/subscription/cosmos-db-data.bicep' = if (cosmosAccountOptions.enabled) {
  name: 'Authorization-Functions-CosmosAccount'
  params: {
    principalId: userAssignedIdentity_application.outputs.principalId
    cosmosAccountName: cosmosAccountOptions.enabled ? extra_cosmos.outputs.name : ''
    roleType: 'Contributor'
  }
}

@description('Contribution authorization to extra Cosmos DB Accounts')
@batchSize(1) // This is needed because Azure Cosmos DB assignements can't be performed in parallel
module auth_contributors_cosmos '../modules/authorizations/subscription/cosmos-db-data.bicep' = [for (group, index) in contributionGroups: if (cosmosAccountOptions.enabled && !empty(contributionGroups)) {
  name: empty(group) ? 'empty' : 'Authorization-ContributionGroup-${index}-CosmosAccount'
  params: {
    principalId: group.id
    cosmosAccountName: cosmosAccountOptions.enabled ? extra_cosmos.outputs.name : ''
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
    principalId: userAssignedIdentity_application.outputs.principalId
    storageAccountName: stg.outputs.name
    roleType: 'Owner'
    roleDescription: 'Functions application should manage technical data from Storage Account'
  }
}

@description('Clients UAI to extra Service Bus')
module auth_clients_extra_sbn '../modules/authorizations/subscription/service-bus-data.bicep' = if (serviceBusOptions.enabled && contains(serviceBusOptions, 'authorizeClients') && serviceBusOptions.authorizeClients) {
  name: 'Authorization-Clients-ServiceBus'
  params: {
    principalId: userAssignedIdentity_clients.outputs.principalId
    serviceBusNamespaceName: serviceBusOptions.enabled ? extra_sbn.outputs.name : ''
    roleType: 'Sender'
    roleDescription: 'Functions application clients should write messages to Service Bus'
  }
}

@description('Clients UAI to extra Storage Accounts')
module auth_clients_extra_stg '../modules/authorizations/subscription/storage-blob-data.bicep' = [for (storageAccountOptions, index) in storageAccounts: if (storageAccountsOptions.enabled && contains(storageAccountOptions, 'authorizeClients') && storageAccountOptions.authorizeClients) {
  name: empty(storageAccountOptions) ? 'empty' : 'Authorization-Clients-StorageAccount${storageAccountOptions.suffix}'
  params: {
    principalId: userAssignedIdentity_clients.outputs.principalId
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
