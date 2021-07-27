// Deploy a Storage Account with blob containers
// Resources deployed from this template:
//   - Storage Account
//   - Blob containers
// Required parameters:
//   - `storageAccountName`
// Optional parameters:
//   - `blobContainers`
// Outputs:
//   - `id`
//   - `apiVersion`
//   - `name`
//   - `accountKey`

// === PARAMETERS ===

@description('The Storage Account name')
param storageAccountName string

@description('The blob containers')
param blobContainers array = []

// === VARIABLES ===

var location = resourceGroup().location

// === RESOURCES ===

// Storage Account
resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

// === OUTPUTS ===

output id string = stg.id
output apiVersion string = stg.apiVersion
output name string = stg.name
output accountKey string = listKeys(stg.id, stg.apiVersion).keys[0].value
