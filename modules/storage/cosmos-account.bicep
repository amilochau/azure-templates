/*
  Deploy a Cosmos DB Account
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The pricing plan')
@allowed([
  'Free'    // The cheapest plan, can create some small fees
  'Basic'   // Basic use with default limitations
])
param pricingPlan string

@description('The Cosmos account options')
param cosmosAccountOptions object

@description('The deployment location')
param location string

// === VARIABLES ===

var cosmosAccountName = '${conventions.naming.prefix}${conventions.naming.suffixes.cosmosAccount}'
var cosmosDatabaseName = '${conventions.naming.prefix}${conventions.naming.suffixes.cosmosDatabase}'
var cosmosApplyFirewall = referential.environment == 'Production'
var knownIpAddresses = loadJsonContent('../global/ip-addresses.json')
var authorizedIpAddresses = union(knownIpAddresses.azurePortal, knownIpAddresses.azureServices)
var ipRules = [ for ipAddress in items(authorizedIpAddresses) : {
  ipAddressOrRange: ipAddress.value
}]
var backupTier = pricingPlan == 'Basic' ? 'Continuous30Days' : 'Continuous7Days'
var zoneRedundant = pricingPlan == 'Basic'

// === RESOURCES ===

@description('Cosmos DB Account')
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15-preview' = {
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
        isZoneRedundant: zoneRedundant
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
    enableAutomaticFailover: true
    backupPolicy: {
      type: 'Continuous'
      continuousModeProperties: {
        tier: backupTier
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
    resource containers 'containers' = [for (container, index) in cosmosAccountOptions.containers: {
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
              path: '"/"_etag"/?"'
            }] : container.excludedPaths
          }
          defaultTtl: !contains(container, 'defaultTtl') ? -1 : container.defaultTtl
        }
      }
    }]
  }
}

@description('Lock')
module lock '../authorizations/locks/cosmos-db-delete.bicep' = {
  name: '${cosmosAccountName}-Resource-Lock-Delete'
  params: {
    cosmosAccountName: cosmosAccount.name
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = cosmosAccount.id

@description('The API Version of the deployed resource')
output apiVersion string = cosmosAccount.apiVersion

@description('The Name of the deployed resource')
output name string = cosmosAccount.name
