/*
  Deploy authorizations for a Storage Account
  Resources deployed from this template:
    - Authorizations
  Required parameters:
    - `principalId`
    - `storageAccountName`
  Optional parameters:
    - `readOnly`
  Optional parameters:
    [None]
  Outputs:
    [None]
*/

// === PARAMETERS ===

@description('Principal ID')
param principalId string

@description('Storage Account name')
param storageAccountName string

@description('Assign a Read-Only authorization')
param readOnly bool = false

// === VARIABLES ===

var buildInRoles = json(loadTextContent('./build-in-roles.json'))
var roleDefinitionId = readOnly ? roleStorageBlobDataReader.id : roleStorageBlobDataOwner.id

// === EXISTING ===

// Roles
resource roleStorageBlobDataOwner 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: buildInRoles['Storage Blob Data Owner']
}
resource roleStorageBlobDataReader 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: buildInRoles['Storage Blob Data Reader']
}

// Storage account
resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

// === AUTHORIZATIONS ===

// Principal to Storage account
resource auth_app_stg 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(principalId, stg.id, roleDefinitionId)
  scope: stg
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
  }
}
