/*
  Deploy a Cosmos DB Account
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

// === VARIABLES ===

var location = resourceGroup().location
var cosmosAccountName = '${conventions.naming.prefix}${conventions.naming.suffixes.cosmosDatabase}'
var extendedRecoverability = referential.environment == 'Production'
var cosmosAccountBackupRedundancy = extendedRecoverability ? 'Geo' : 'Local'

// === RESOURCES ===

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2021-10-15' = {
  name: cosmosAccountName
  tags: referential
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
      }
    ]
    backupPolicy: {
      type: 'Periodic'
      periodicModeProperties: {
        backupIntervalInMinutes: 1440
        backupRetentionIntervalInHours: 720
        backupStorageRedundancy: cosmosAccountBackupRedundancy
      }
    }
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
    enableFreeTier: false
  }
}

// === OUTPUTS ===

@description('The ID of the deployed Cosmos DB Account')
output id string = cosmosAccount.id

@description('The API Version of the deployed Cosmos DB Account')
output apiVersion string = cosmosAccount.apiVersion

@description('The Name of the deployed Cosmos DB Account')
output name string = cosmosAccount.name
