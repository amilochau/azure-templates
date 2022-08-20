/*
  Deploy a management group
*/

targetScope = 'managementGroup'

// === PARAMETERS ===

@description('The groups with their ID and the role to attribute')
param groups array = []

// === VARIABLES ===

@description('Global & naming conventions')
var buildInRoles = loadJsonContent('../modules/global/built-in-roles.json')

// === RESOURCES ===

@description('Policies - Security')
module policies_security '../modules/authorizations/initiatives/security/security.bicep' = {
  name: 'Initiative-security'
}

// === AUTHORIZATIONS ===

@description('Principal to Resources')
module authorizations '../modules/authorizations/management-group/group-role.bicep' = [for group in groups: {
  name: 'Authorization-${guid(group.id, group.role)}'
  params: {
    principalId: group.id
    roleName: buildInRoles[group.role]
  }
}]
