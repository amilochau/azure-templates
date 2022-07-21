/*
  Deploy infrastructure to test a local Azure Functions application, with a Key Vault, service bus and storage account resources
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


@description('''
The service bus options:
- **enabled**: bool
- **queues**: string[]
''')
param serviceBusOptions object = {
  enabled: false
}

@description('''
The storage accounts options:
- **enabled**: bool
- **accounts**: array
  - *suffix*: string
  - **comment**: string
  - **containers**: string[]
  - *daysBeforeDeletion*: int
  - *allowBlobPublicAccess*: bool
''')
param storageAccountsOptions object = {
  enabled: false
}

@description('''
The Cosmos account options:
- **enabled**: bool
- **containers**: array
  - **name**
  - **partitionKey**
  - *uniqueKeys*
  - *compositeIndexes*
  - *includedPaths*
  - *excludedPaths*
  - *defaultTtl*
''')
param cosmosAccountOptions object = {
  enabled: false
}

@description('The contribution groups')
param contributionGroups array = []

@description('The deployment location')
param location string = resourceGroup().location

// === VARIABLES ===

@description('The region name')
var regionName = loadJsonContent('../modules/global/regions.json')[location]

@description('Global & naming conventions')
var conventions = json(replace(replace(replace(replace(loadTextContent('../modules/global/conventions.json'), '%ORGANIZATION%', organizationName), '%APPLICATION%', applicationName), '%HOST%', hostName), '%REGION%', regionName))

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
module extra_stg '../modules/storage/storage-account.bicep' = [for storageAccountOptions in storageAccountsOptions.accounts: if (storageAccountsOptions.enabled) {
  name: !contains(storageAccountOptions, 'suffix') ? 'empty' : 'Resource-StorageAccount-${storageAccountOptions.suffix}'
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
    location: location
    cosmosAccountOptions: cosmosAccountOptions
  }
}

// === AUTHORIZATIONS ===

@description('Contribution authorization to extra Cosmos DB Accounts')
module auth_contributors_cosmos '../modules/authorizations/subscription/cosmos-db-data.bicep' = [for (group, index) in contributionGroups: if (!empty(contributionGroups)) {
  name: empty(group) ? 'empty' : 'Authorization-ContributionGroup-${index}-CosmosAccount'
  params: {
    principalId: group.id
    cosmosAccountName: extra_cosmos.outputs.name
    roleType: 'Contributor'
  }
}]
