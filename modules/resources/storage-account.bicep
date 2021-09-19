/*
  Deploy a Storage Account with blob containers
  Resources deployed from this template:
    - Storage Account
    - Blob containers
  Required parameters:
    - `referential`
    - `comment`
  Optional parameters:
    - `number`
    - `blobContainers`: []
       - `name`
    - `daysBeforeDeletion`
    - `allowBlobPublicAccess`
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The storage account comment')
param comment string

@description('The storage account number')
param number string = ''

@description('The blob containers')
param blobContainers array = []

@description('Duration before blobs deletion in days - 0 disable this feature')
param daysBeforeDeletion int = 0

@description('Allow blob public access')
param allowBlobPublicAccess bool = false

// === VARIABLES ===

var location = resourceGroup().location
var baseStorageAccountName = '${referential.organization}-${referential.application}-${referential.host}-sto'
var fullStorageAccountName = empty(number) ? baseStorageAccountName : '${baseStorageAccountName}-${number}'
var storageAccountName = replace(fullStorageAccountName, '-','')
var commentTag = {
  comment: comment
}
var tags = union(referential, commentTag)

// === RESOURCES ===

// Storage Account
resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
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
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }

  resource stg_lifecycle 'managementPolicies@2021-04-01' = if (daysBeforeDeletion > 0) {
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

  resource stg_blobServices 'blobServices@2021-04-01' = {
    name: 'default'
    properties: {
      deleteRetentionPolicy: {
        enabled: false
      }
    }
    
    resource stg_containers 'containers@2021-04-01' = [for container in blobContainers: if (length(blobContainers) > 0) {
      name: container
      properties: {
        publicAccess: allowBlobPublicAccess ? 'Blob' : 'None'
      }
    }]
  }
}

// === OUTPUTS ===

output id string = stg.id
output apiVersion string = stg.apiVersion
output name string = stg.name
