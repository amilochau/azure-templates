/*
  Deploy authorizations for an Application Insights
*/

// === PARAMETERS ===

@description('Principal ID')
param principalId string

@description('Application Insights name')
param applicationInsightsName string

@description('The role description')
param roleDescription string

// === VARIABLES ===

var buildInRoles = json(loadTextContent('./build-in-roles.json'))

// === EXISTING ===

@description('Role - Monitoring Metrics Publisher')
resource roleMonitoringMetricsPublisher 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: buildInRoles['Monitoring Metrics Publisher']
}

@description('Application Insights')
resource ai 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: applicationInsightsName
}

// === AUTHORIZATIONS ===

@description('Principal to Application Insights')
resource auth_app_kv 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(principalId, ai.id, roleMonitoringMetricsPublisher.id)
  scope: ai
  properties: {
    roleDefinitionId: roleMonitoringMetricsPublisher.id
    principalId: principalId
    description: roleDescription
    principalType: 'ServicePrincipal'
  }
}
