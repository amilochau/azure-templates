/*
  Deploy authorizations for an Application Insights
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

@description('Application Insights name')
param applicationInsightsName string

@description('The role type')
@allowed([
  'Metrics Publisher' // Recommended for most use cases
  'Reader'
])
param roleType string

@description('The role description')
param roleDescription string

// === VARIABLES ===

var buildInRoles = loadJsonContent('../../global/built-in-roles.json')
var roleName = roleType == 'Metrics Publisher' ? buildInRoles['Monitoring Metrics Publisher'] : buildInRoles['Monitoring Reader']

// === EXISTING ===

@description('Role')
resource role 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: roleName
}

@description('Application Insights')
resource ai 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: applicationInsightsName
}

// === AUTHORIZATIONS ===

@description('Principal to Application Insights')
resource auth_app_kv 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(principalId, ai.id, role.id)
  scope: ai
  properties: {
    roleDefinitionId: role.id
    principalId: principalId
    description: roleDescription
    principalType: principalType
  }
}
