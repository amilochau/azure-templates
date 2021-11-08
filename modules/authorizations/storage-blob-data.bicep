/*
  Deploy authorizations for a Storage Account
*/

// === PARAMETERS ===

@description('Principal ID')
param principalId string

@description('Storage Account name')
param storageAccountName string

@description('Assign a Read-Only authorization')
param readOnly bool = false

@description('The role description')
param roleDescription string

// === VARIABLES ===

var buildInRoles = json(loadTextContent('./build-in-roles.json'))
var roleDefinitionId = readOnly ? roleStorageBlobDataReader.id : roleStorageBlobDataOwner.id

// === EXISTING ===

@description('Role - Storage Blob Data Owner')
resource roleStorageBlobDataOwner 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: buildInRoles['Storage Blob Data Owner']
}

@description('Role - Storage Blob Data Reader')
resource roleStorageBlobDataReader 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: buildInRoles['Storage Blob Data Reader']
}

@description('Storage account')
resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

// === AUTHORIZATIONS ===

@description('Principal to Storage account')
resource auth_app_stg 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(principalId, stg.id, roleDefinitionId)
  scope: stg
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    description: roleDescription
    principalType: 'ServicePrincipal'
  }
}
