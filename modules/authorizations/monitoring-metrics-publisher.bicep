/*
  Deploy authorizations for an Application Insights
  Resources deployed from this template:
    - Authorizations
  Required parameters:
    - `principalId`
    - `applicationInsightsName`
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

// === VARIABLES ===

var roleDefinitionIds = {
  'Monitoring Metrics Publisher': '3913510d-42f4-4e42-8a64-420c390055eb'
}

// === EXISTING ===

// Role
resource roleMonitoringMetricsPublisher 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: roleDefinitionIds['Monitoring Metrics Publisher']
}

// Application Insights
resource ai 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: applicationInsightsName
}

// === AUTHORIZATIONS ===

// Principal to Application Insights
resource auth_app_kv 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id, principalId, ai.id)
  scope: ai
  properties: {
    roleDefinitionId: roleMonitoringMetricsPublisher.id
    principalId: principalId
  }
}
