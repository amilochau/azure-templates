/*
  Deploy a Storage Account with blob containers
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The storage account options')
param storageAccountOptions object

@description('The deployment location')
param location string

// === VARIABLES ===

var storageAccountName = '${conventions.naming.prefix}${conventions.naming.suffixes.storageAccount}${suffix}'
var extendedRecoverability = referential.environment == 'Production'
var storageAccountSku = extendedRecoverability ? 'Standard_GRS' : 'Standard_LRS'
var specificTags = {
  comment: storageAccountOptions.comment
}
var tags = union(referential, specificTags)
var suffix = contains(storageAccountOptions, 'suffix') ? storageAccountOptions.suffix : ''
var daysBeforeDeletion = contains(storageAccountOptions, 'daysBeforeDeletion') ? storageAccountOptions.daysBeforeDeletion : 0
var allowBlobPublicAccess = contains(storageAccountOptions, 'allowBlobPublicAccess') ? storageAccountOptions.allowBlobPublicAccess : false

// === RESOURCES ===

@description('Storage Account')
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: replace(storageAccountName, '-', '')
  location: location
  kind: 'StorageV2'
  sku: {
    name: storageAccountSku
  }
  tags: tags
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: false // false = Enforcing AAD as the only authentication method
    allowCrossTenantReplication: false
    allowedCopyScope: 'AAD'
    defaultToOAuthAuthentication: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
        }
      }
    }
  }

  // Storage lifecycle policy
  resource lifecycle 'managementPolicies' = if (daysBeforeDeletion > 0) {
    name: 'default'
    properties: {
      policy: {
        rules: [
          {
            name: 'auto-deletion'
            type: 'Lifecycle'
            definition: {
              filters: {
                blobTypes: [
                  'blockBlob'
                ]
              }
              actions: {
                 baseBlob: {
                    delete: {
                      daysAfterModificationGreaterThan: daysBeforeDeletion
                    }
                 }
              }
            }
          }
        ]
      }
    }
  }

  // Blob services
  resource blobServices 'blobServices' = {
    name: 'default'
    properties: {
      changeFeed: {
        enabled: extendedRecoverability
        retentionInDays: 7
      }
      deleteRetentionPolicy: {
        enabled: extendedRecoverability
        days: 14
      }
      containerDeleteRetentionPolicy: {
        enabled: extendedRecoverability
        days: 14
      }
    }
    
    // Blob containers
    resource containers 'containers' = [for container in storageAccountOptions.containers: if (length(storageAccountOptions.containers) > 0) {
      name: container
      properties: {
        publicAccess: allowBlobPublicAccess ? 'Blob' : 'None'
      }
    }]
  }
}

@description('Lock')
module lock '../authorizations/locks/storage-delete.bicep' = {
  name: 'Resource-Lock-Delete'
  params: {
    storageAccountName: storageAccount.name
  }
}

@description('CDN')
module cdn '../cache/cdn-on-storage.bicep' = if (allowBlobPublicAccess) {
  name: 'Resource-CDN-${suffix}'
  params: {
    referential: referential
    conventions: conventions
    location: location
    storageAccountHostName: replace(replace(storageAccount.properties.primaryEndpoints.blob, 'https://', ''), '/', '')
    storageAccountComment: storageAccountOptions.comment
    storageAccountSuffix: suffix
    cdnCacheExpirationInDays: 360
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = storageAccount.id

@description('The API Version of the deployed resource')
output apiVersion string = storageAccount.apiVersion

@description('The Name of the deployed resource')
output name string = storageAccount.name
