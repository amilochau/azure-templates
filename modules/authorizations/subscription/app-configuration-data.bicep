/*
  Deploy authorizations for an Azure App Configuration
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

@description('App Configuration name')
param appConfigurationName string

@description('The role type')
@allowed([
  'Owner'
  'Reader' // Recommended for most use cases
])
param roleType string

@description('The role description')
param roleDescription string

// === VARIABLES ===

var buildInRoles = loadJsonContent('../../global/built-in-roles.json')
var roleName = roleType == 'Owner' ? buildInRoles['App Configuration Data Owner'] : buildInRoles['App Configuration Data Reader']

// === EXISTING ===

@description('Role')
resource role 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: roleName
}

@description('App Configuration')
resource appConfig 'Microsoft.AppConfiguration/configurationStores@2021-03-01-preview' existing = {
  name: appConfigurationName
}

// === AUTHORIZATIONS ===

@description('Principal to App Configuration')
resource auth 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(principalId, appConfig.id, role.id)
  scope: appConfig
  properties: {
    roleDefinitionId: role.id
    principalId: principalId
    description: roleDescription
    principalType: principalType
  }
}
