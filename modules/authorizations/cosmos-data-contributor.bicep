/*
  Deploy authorizations for a Cosmos DB account
*/

// === PARAMETERS ===

@description('Principal ID')
param principalId string

@description('Cosmos DB Account name')
param cosmosAccountName string

// === VARIABLES ===

var buildInRoles = json(loadTextContent('../global/built-in-roles.json'))
var roleName = buildInRoles['cosmos']['Cosmos DB Built-in Data Contributor']

// === EXISTING ===

@description('Cosmos DB account')
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2021-10-15' existing = {
  name: cosmosAccountName
}

@description('Role - Cosmos DB Data Contributor')
resource roleCosmosDataContributor 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2021-10-15' existing = {
  name: roleName
  parent: cosmosAccount
}
// === AUTHORIZATIONS ===

@description('Principal to Cosmos DB account')
resource auth_app_cosmos 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2021-10-15' = {
  name: guid(principalId, cosmosAccount.id, roleCosmosDataContributor.id)
  properties: {
    principalId: principalId
    roleDefinitionId: roleCosmosDataContributor.id
    scope: '/'
  }
}
