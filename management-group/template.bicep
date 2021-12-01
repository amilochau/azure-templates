/*
  Deploy a management group
*/

targetScope = 'managementGroup'

// === PARAMETERS ===

@description('The principal ID for Azure resources administrators')
param administratorsGroupPrincipalId string

// === VARIABLES ===

@description('Global & naming conventions')
var buildInRoles = json(loadTextContent('../modules/authorizations/build-in-roles.json'))

// === AUTHORIZATIONS ===

@description('Principal to App Configuration')
module group_appConfig '../modules/authorizations/management-group/group-role.bicep' = {
  name: 'Authorization-AppConfiguration'
  params: {
    roleName: buildInRoles['App Configuration Data Reader']
    principalId: administratorsGroupPrincipalId
  }
}
