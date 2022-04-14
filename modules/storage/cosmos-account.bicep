/*
  Deploy a Cosmos DB Account
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('the Cosmos DB containers')
param cosmosContainers array

@description('The deployment location')
param location string

// === VARIABLES ===

var cosmosAccountName = '${conventions.naming.prefix}${conventions.naming.suffixes.cosmosAccount}'
var cosmosDatabaseName = '${conventions.naming.prefix}${conventions.naming.suffixes.cosmosDatabase}'
var extendedRecoverability = referential.environment == 'Production'
var cosmosAccountBackupRedundancy = extendedRecoverability ? 'Geo' : 'Local'
var knownIpAddresses = json(loadTextContent('../global/ip-addresses.json'))
var authorizedIpAddresses = union(knownIpAddresses['azurePortal'], knownIpAddresses['azureServices'])

// === RESOURCES ===

@description('Cosmos DB Account')
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2021-10-15' = {
  name: cosmosAccountName
  tags: referential
  kind: 'GlobalDocumentDB'
  location: location
  properties: {
    databaseAccountOfferType: 'Standard'
    disableLocalAuth: true // true = Enforcing RBAC as the only authentication method
    disableKeyBasedMetadataWriteAccess: true
    enableFreeTier: false
    locations: [
      {
        locationName: location
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
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
    ipRules: [ for ipAddress in items(authorizedIpAddresses) : {
      ipAddressOrRange: ipAddress.value
    }]
  }

  // Cosmos DB Database
  resource database 'sqlDatabases@2021-10-15' = {
    name: cosmosDatabaseName
    properties: {
      resource: {
        id: cosmosDatabaseName
      }
    }

    // Cosmos DB Containers
    resource containers 'containers@2021-10-15' = [for (container, index) in cosmosContainers: {
      name: container.name
      location: location
      tags: referential
      properties: {
        resource: {
          id: container.name
          partitionKey: {
            kind: 'Hash'
            paths: [
              container.partitionKey
            ]
            version: 2
          }
          uniqueKeyPolicy: {
            uniqueKeys: [for (uniqueKey, indexKey) in container.uniqueKeys: {
              paths: [
                uniqueKey
              ]
            }]
          }
        }
      }
    }]
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = cosmosAccount.id

@description('The API Version of the deployed resource')
output apiVersion string = cosmosAccount.apiVersion

@description('The Name of the deployed resource')
output name string = cosmosAccount.name
