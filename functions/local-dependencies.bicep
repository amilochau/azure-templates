/*
  Deploy infrastructure to test a local Azure Functions application
  Resources deployed from this template:
    - Key Vault
    - Service Bus namespace and queues
    - Storage accounts, storage containers and CDN
  Required parameters:
    - `organizationName`
    - `applicationName`
    - `environmentName`
    - `hostName`
  Optional parameters:
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
module kv '../modules/resources/key-vault/vault.bicep' = if (secrets.enableKeyVault) {
  name: 'Resource-KeyVault'
  params: {
    referential: tags.outputs.referential
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
