/*
  Deploy infrastructure to test a local Azure Functions application
  Resources deployed from this template:
    - Key Vault
    - Service Bus namespace and queues
    - Storage accounts, storage containers and CDN
  Required parameters:
    - `organizationName`
    - `applicationName`
    - `hostName`
  Optional parameters:
    - `disableKeyVault`
    - `serviceBusQueues`: []
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


@description('Whether to disable the Key Vault')
param disableKeyVault bool = false

@description('The service bus queues')
param serviceBusQueues array = []

@description('The storage accounts')
param storageAccounts array = []

// === VARIABLES ===

var conventions = json(replace(replace(replace(loadTextContent('../modules/global/conventions.json'), '%ORGANIZATION', organizationName), '%APPLICATION%', applicationName), '%HOST%', hostName))

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
