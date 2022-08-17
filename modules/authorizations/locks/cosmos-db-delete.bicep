/*
  Deploy a delete lock for a Cosmos DB account
*/

// === PARAMETERS ===

@description('Cosmos DB Account name')
param cosmosAccountName string

// === EXISTING ===

@description('Cosmos DB account')
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15-preview' existing = {
  name: cosmosAccountName
}

// === AUTHORIZATIONS ===

@description('Lock')
resource lock 'Microsoft.Authorization/locks@2017-04-01' = { // @2020-05-01 is not available in westeurope
  name: '${cosmosAccount.name}-lock-delete'
  scope: cosmosAccount
  properties: {
    level: 'CanNotDelete'
    notes: 'Cosmos DB accounts, databases and containers should not be deleted, to avoid data loss.'
  }
}
