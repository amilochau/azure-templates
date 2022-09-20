/*
  Deploy infrastructure for Web application, with Application Insights, Key Vault resources, authorizations
*/

// === PARAMETERS ===

@description('The organization name')
@minLength(3)
@maxLength(3)
param organizationName string

@description('The application name')
@minLength(2)
@maxLength(14)
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
  - *customDomains*: string[]
  - *authorizeClients*: bool
  - *role*: enum { Owner, Contributor, Reader }
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
The Web app options:
- **dockerRegistryServer**:
  - *host*: string
  - *username*: string
  - *password*: string
- *extraAppSettings*: dictionary
- *extraIdentities*: dictionary
- *extraSlots*: array
  - **name**
- *openId*:
  - **clientSecretKey**: string
  - **endpoint**: string
  - **apiClientId**: string
  - *skipAuthentication*: bool
  - *anonymousEndpoints*: array
- *existingAppServicePlanId*: string
''')
param webAppOptions object

@description('The application Docker image reference')
param applicationImageReference string = 'mcr.microsoft.com/appsvc/staticsite:latest'

@description('The contribution groups')
param contributionGroups array = []

@description('The deployment location')
param location string = resourceGroup().location

// === VARIABLES ===

@description('The region name')
var regionName = loadJsonContent('../modules/global/regions.json')[location].name

@description('Global & naming conventions')
var conventions = json(replace(replace(replace(replace(loadTextContent('../modules/global/conventions.json'), '%ORGANIZATION%', organizationName), '%APPLICATION%', applicationName), '%HOST%', hostName), '%REGION%', regionName))

@description('Extended monitoring')
var extendedMonitoring = startsWith(hostName, 'prd')

@description('The storage accounts')
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

@description('Service Plan')
module asp '../modules/applications/web/service-plan.bicep' = if (!contains(webAppOptions, 'existingAppServicePlanId')) {
  name: 'Resource-ServerFarm'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    pricingPlan: pricingPlan
    location: location
  }
}

@description('Web application')
module web '../modules/applications/web/application.bicep' = {
  name: 'Resource-WebApplication'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    userAssignedIdentityId: userAssignedIdentity_application.outputs.id
    userAssignedIdentityClientId: userAssignedIdentity_application.outputs.clientId
    serverFarmId: contains(webAppOptions, 'existingAppServicePlanId') ? webAppOptions.existingAppServicePlanId : asp.outputs.id
    aiConnectionString: ai.outputs.connectionString
    kvVaultUri: kv.outputs.vaultUri
    webAppOptions: webAppOptions
    applicationImageReference: applicationImageReference
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

@description('Availability tests on Web application')
module webTest_web '../modules/monitoring/web-tests/api-availability.bicep' = if (extendedMonitoring) {
  name: 'Resource-AvailabilityTests-Web'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    applicationInsightsId: ai.outputs.id
    applicationHostName: web.outputs.defaultHostName
  }
}

@description('Availability tests on Static Web Apps application')
module webTest_swa '../modules/monitoring/web-tests/ui-availability.bicep' = if (staticWebAppOptions.enabled && extendedMonitoring) {
  name: 'Resource-AvailabilityTests-StaticWebApps'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    applicationInsightsId: ai.outputs.id
    applicationHostName: staticWebAppOptions.enabled ? swa.outputs.defaultHostName : ''
    
  }
}

// === AUTHORIZATIONS ===

@description('Web to Key Vault')
module auth_fn_kv '../modules/authorizations/subscription/key-vault-secrets-data.bicep' = {
  name: 'Authorization-Web-KeyVault'
  params: {
    principalId: userAssignedIdentity_application.outputs.principalId
    keyVaultName: kv.outputs.name
    roleType: 'Reader'
    roleDescription: 'Web application should read the secrets from Key Vault'
  }
}

@description('Web to Application Insights')
module auth_fn_ai '../modules/authorizations/subscription/monitoring-data.bicep' = {
  name: 'Authorization-Web-ApplicationInsights'
  params: {
    principalId: userAssignedIdentity_application.outputs.principalId
    applicationInsightsName: ai.outputs.name
    roleType: 'Metrics Publisher'
    roleDescription: 'Web application should send monitoring metrics into Application Insights'
  }
}

@description('Web to extra Service Bus')
module auth_fn_extra_sbn '../modules/authorizations/subscription/service-bus-data.bicep' = if (serviceBusOptions.enabled) {
  name: 'Authorization-Web-ServiceBus'
  params: {
    principalId: userAssignedIdentity_application.outputs.principalId
    serviceBusNamespaceName: serviceBusOptions.enabled ? extra_sbn.outputs.name : ''
    roleType: 'Owner'
    roleDescription: 'Web application should read, write and manage the messages from Service Bus'
  }
}

@description('Web to extra Storage Accounts')
module auth_fn_extra_stg '../modules/authorizations/subscription/storage-blob-data.bicep' = [for (storageAccountOptions, index) in storageAccounts: if (storageAccountsOptions.enabled) {
  name: empty(storageAccountOptions) ? 'empty' : 'Authorization-Web-StorageAccount${storageAccountOptions.suffix}'
  params: {
    principalId: userAssignedIdentity_application.outputs.principalId
    storageAccountName: extra_stg[index].outputs.name
    roleType: contains(storageAccountOptions, 'role') ? storageAccountOptions.role : 'Contributor'
    roleDescription: 'Web application should read/write the blobs from Storage Account'
  }
}]

@description('Web to extra Cosmos DB Account')
module auth_fn_extra_cosmos '../modules/authorizations/subscription/cosmos-db-data.bicep' = if (cosmosAccountOptions.enabled) {
  name: 'Authorization-Web-CosmosAccount'
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

@description('Clients UAI to extra Service Bus')
module auth_clients_extra_sbn '../modules/authorizations/subscription/service-bus-data.bicep' = if (serviceBusOptions.enabled && contains(serviceBusOptions, 'authorizeClients') && serviceBusOptions.authorizeClients) {
  name: 'Authorization-Clients-ServiceBus'
  params: {
    principalId: userAssignedIdentity_clients.outputs.principalId
    serviceBusNamespaceName: serviceBusOptions.enabled ? extra_sbn.outputs.name : ''
    roleType: 'Sender'
    roleDescription: 'Web application clients should write messages to Service Bus'
  }
}

@description('Clients UAI to extra Storage Accounts')
module auth_clients_extra_stg '../modules/authorizations/subscription/storage-blob-data.bicep' = [for (storageAccountOptions, index) in storageAccounts: if (storageAccountsOptions.enabled && contains(storageAccountOptions, 'authorizeClients') && storageAccountOptions.authorizeClients) {
  name: empty(storageAccountOptions) ? 'empty' : 'Authorization-Clients-StorageAccount${storageAccountOptions.suffix}'
  params: {
    principalId: userAssignedIdentity_clients.outputs.principalId
    storageAccountName: extra_stg[index].outputs.name
    roleType: 'Contributor'
    roleDescription: 'Web application clients should read & write the blobs from Storage Account'
  }
}]

// === OUTPUTS ===

@description('The ID of the deployed resource')
output resourceId string = web.outputs.id

@description('The Name of the deployed resource')
output resourceName string = web.outputs.name
