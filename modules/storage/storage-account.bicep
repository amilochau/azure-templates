/*
  Deploy a Storage Account with blob containers
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The storage account comment')
param comment string

@description('The storage account suffix')
param suffix string = ''

@description('The blob containers')
param blobContainers array = []

@description('Duration before blobs deletion in days - 0 disables this feature')
param daysBeforeDeletion int = 0

@description('Allow blob public access')
param allowBlobPublicAccess bool = false

@description('The pricing plan')
@allowed([
  'Free'    // The cheapest plan, can create some small fees
  'Basic'   // Basic use with default limitations
])
param pricingPlan string

// === VARIABLES ===

var location = resourceGroup().location
var storageAccountName = '${conventions.naming.prefix}${conventions.naming.suffixes.storageAccount}${suffix}'
var extendedRecoverability = referential.environment == 'Production'
var storageAccountSku = extendedRecoverability ? 'Standard_GRS' : 'Standard_LRS'
var commentTag = {
  comment: comment
}
var tags = union(referential, commentTag)

// === RESOURCES ===

@description('Storage Account')
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
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
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }

  // Storage lifecycle policy
  resource lifecycle 'managementPolicies@2021-04-01' = if (daysBeforeDeletion > 0) {
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
  resource blobServices 'blobServices@2021-04-01' = {
    name: 'default'
    properties: {
      isVersioningEnabled: pricingPlan != 'Free'
      changeFeed: {
        enabled: pricingPlan != 'Free'
      }
      deleteRetentionPolicy: {
        enabled: extendedRecoverability
        days: 90
      }
      restorePolicy: {
        enabled: extendedRecoverability
        days: 30
      }
      containerDeleteRetentionPolicy: {
        enabled: extendedRecoverability
        days: 30
      }
    }
    
    // Blob containers
    resource containers 'containers@2021-04-01' = [for container in blobContainers: if (length(blobContainers) > 0) {
      name: container
      properties: {
        publicAccess: allowBlobPublicAccess ? 'Blob' : 'None'
      }
    }]
  }
}

@description('CDN')
module cdn '../cache/cdn-on-storage.bicep' = if (allowBlobPublicAccess) {
  name: 'Resource-CDN-${suffix}'
  params: {
    referential: referential
    conventions: conventions
    storageAccountHostName: replace(replace(storageAccount.properties.primaryEndpoints.blob, 'https://', ''), '/', '')
    storageAccountComment: comment
    storageAccountSuffix: suffix
    cdnCacheExpirationInDays: 360
  }
}

// === OUTPUTS ===

@description('The ID of the deployed Storage Account')
output id string = storageAccount.id

@description('The API Version of the deployed Storage Account')
output apiVersion string = storageAccount.apiVersion

@description('The Name of the deployed Storage Account')
output name string = storageAccount.name
