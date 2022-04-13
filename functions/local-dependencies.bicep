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


@description('The service bus queues')
param serviceBusQueues array = []

@description('The storage accounts')
param storageAccounts array = []

@description('The Cosmos DB containers')
param cosmosContainers array = []

@description('The contribution groups')
param contributionGroups array = []

@description('The deployment location')
param location string = resourceGroup().location

// === VARIABLES ===

@description('The region name')
var regionName = json(loadTextContent('../modules/global/regions.json'))[location]

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

@description('Key Vault')
module kv '../modules/configuration/key-vault.bicep' = {
  name: 'Resource-KeyVault'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
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

// === AUTHORIZATIONS ===

@description('Contribution authorization to extra Cosmos DB Accounts')
module auth_contributors_cosmos '../modules/authorizations/cosmos-data-contributor.bicep' = [for (group, index) in contributionGroups: if (!empty(contributionGroups)) {
  name: empty(group) ? 'empty' : 'Authorization-ContributionGroup-${index}-CosmosAccount'
  params: {
    principalId: group.id
    cosmosAccountName: extra_cosmos.outputs.name
  }
}]
