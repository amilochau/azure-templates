/*
  Deploy a management group
*/

targetScope = 'managementGroup'

// === PARAMETERS ===

@description('The groups with their ID and the role to attribute')
param groups array = []

// === VARIABLES ===

@description('Global & naming conventions')
var buildInRoles = json(loadTextContent('../modules/authorizations/build-in-roles.json'))

// === AUTHORIZATIONS ===

@description('Principal to App Configuration')
module authorizations '../modules/authorizations/management-group/group-role.bicep' = [for group in groups: {
  name: 'Authorization-${guid(group.id, group.role)}'
  params: {
    principalId: group.id
    roleName: buildInRoles[group.role]
  }
}]
