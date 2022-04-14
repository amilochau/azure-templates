/*
  Deploy authorizations for a Storage Account
*/

// === PARAMETERS ===

@description('Principal ID')
param principalId string

@description('Principal Type')
@allowed([
  'ServicePrincipal'
  'Group'
])
param principalType string = 'ServicePrincipal'

@description('Storage Account name')
param storageAccountName string

@description('The role type')
@allowed([
  'Owner'
  'Contributor' // Recommended for most use cases
  'Reader'
])
param roleType string

@description('The role description')
param roleDescription string

// === VARIABLES ===

var buildInRoles = json(loadTextContent('../../global/built-in-roles.json'))
var roleName = roleType == 'Owner' ? buildInRoles['Storage Blob Data Owner'] : roleType == 'Contributor' ? buildInRoles['Storage Blob Data Contributor'] : buildInRoles['Storage Blob Data Reader']

// === EXISTING ===

@description('Role')
resource role 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: roleName
}

@description('Storage account')
resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

// === AUTHORIZATIONS ===

@description('Principal to Storage account')
resource auth_app_stg 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(principalId, stg.id, role.id)
  scope: stg
  properties: {
    roleDefinitionId: role.id
    principalId: principalId
    description: roleDescription
    principalType: principalType
  }
}
