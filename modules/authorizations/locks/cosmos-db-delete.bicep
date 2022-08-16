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

@description('Lock on Cosmos DB account')
resource lock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: '${cosmosAccount.name}-lock-delete'
  scope: cosmosAccount
  properties: {
    level: 'CanNotDelete'
    notes: 'Cosmos DB accounts, databases and containers should not be deleted, to avoid data loss.'
  }
}
