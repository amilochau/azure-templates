/*
  Deploy authorizations for a Cosmos DB account
*/

// === PARAMETERS ===

@description('Principal ID')
param principalId string

@description('Cosmos DB Account name')
param cosmosAccountName string

@description('The role type')
@allowed([
  'Contributor' // Recommended for most use cases
  'Reader'
])
param roleType string

// === VARIABLES ===

var buildInRoles = loadJsonContent('../../global/built-in-roles.json')
var roleName = roleType == 'Contributor' ? buildInRoles.cosmos['Cosmos DB Built-in Data Contributor'] : buildInRoles.cosmos['Cosmos DB Built-in Data Reader']

// === EXISTING ===

@description('Role')
resource role 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2022-05-15-preview' existing = {
  name: roleName
  parent: cosmosAccount
}

@description('Cosmos DB account')
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15-preview' existing = {
  name: cosmosAccountName
}

// === AUTHORIZATIONS ===

@description('Principal to Cosmos DB account')
resource auth_app_cosmos 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-05-15-preview' = {
  name: guid(principalId, cosmosAccount.id, role.id)
  parent: cosmosAccount
  properties: {
    principalId: principalId
    roleDefinitionId: role.id
    scope: cosmosAccount.id
  }
}
