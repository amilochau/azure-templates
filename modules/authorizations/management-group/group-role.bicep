/*
  Deploy authorizations to a group, at a management group scope
*/

targetScope = 'managementGroup'

// === PARAMETERS ===

@description('Principal ID')
param principalId string

@description('The role name')
param roleName string

// === EXISTING ===

@description('Role')
resource role 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: roleName
}

// === AUTHORIZATIONS ===

@description('Principal to Managemnt group')
resource auth_app_appConfig 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(principalId, role.id)
  properties: {
    roleDefinitionId: role.id
    principalId: principalId
    principalType: 'Group'
  }
}
