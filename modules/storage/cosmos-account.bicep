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
var cosmosAccountBackupRedundancy = referential.environment == 'Production' ? 'Geo' : 'Local'
var cosmosApplyFirewall = referential.environment == 'Production'
var knownIpAddresses = loadJsonContent('../global/ip-addresses.json')
var authorizedIpAddresses = union(knownIpAddresses.azurePortal, knownIpAddresses.azureServices)
var ipRules = [ for ipAddress in items(authorizedIpAddresses) : {
  ipAddressOrRange: ipAddress.value
}]

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
    ipRules: !cosmosApplyFirewall ? [] : ipRules
  }

  // Cosmos DB Database
  resource database 'sqlDatabases' = {
    name: cosmosDatabaseName
    properties: {
      resource: {
        id: cosmosDatabaseName
      }
    }

    // Cosmos DB Containers
    resource containers 'containers' = [for (container, index) in cosmosContainers: {
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
            uniqueKeys: [for (uniqueKey, indexKey) in !contains(container, 'uniqueKeys') ? [] : container.uniqueKeys: {
              paths: [
                uniqueKey
              ]
            }]
          }
          indexingPolicy: {
            indexingMode: 'consistent'
            automatic: true
            compositeIndexes: !contains(container, 'compositeIndexes') ? [] : container.compositeIndexes
            includedPaths: !contains(container, 'includedPaths') ? [{
              path: '/*'
            }] : container.includedPaths
            excludedPaths: !contains(container, 'excludedPaths') ? [{
              path: '/\\"_etag\\"/?'
            }] : container.excludedPaths
          }
          defaultTtl: !contains(container, 'defaultTtl') ? -1 : container.defaultTtl
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
