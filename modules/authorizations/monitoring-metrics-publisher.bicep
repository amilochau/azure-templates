/*
  Deploy authorizations for an Application Insights
  Resources deployed from this template:
    - Authorizations
  Required parameters:
    - `principalId`
    - `applicationInsightsName`
    - `roleDescription`
  Optional parameters:
    [None]
  Outputs:
    [None]
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

// Role
resource roleMonitoringMetricsPublisher 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: buildInRoles['Monitoring Metrics Publisher']
}

// Application Insights
resource ai 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: applicationInsightsName
}

// === AUTHORIZATIONS ===

// Principal to Application Insights
resource auth_app_kv 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(principalId, ai.id, roleMonitoringMetricsPublisher.id)
  scope: ai
  properties: {
    roleDefinitionId: roleMonitoringMetricsPublisher.id
    principalId: principalId
    description: roleDescription
  }
}
