// Deploy infrastructure for API Management
// Resources deployed from this template:
//   - API Management
//   - Application Insights
// Required parameters:
//   - `organizationName`
//   - `applicationName`
//   - `environmentName`
//   - `hostName`
// Optional parameters:
//   - `api`: {}
//      - `publisherEmail`
//      - `publisherName`
//   - `monitoring`: {}
//      - `enableApplicationInsights`
//      - `disableLocalAuth`
//      - `dailyCap`
//      - `workspaceName`
//      - `workspaceResourceGroup`
// Outputs:
//   [None]

// === PARAMETERS ===

@description('The organization name')
param organizationName string

@description('The application name')
param applicationName string

@description('The environment name of the deployment stage')
param environmentName string

@description('The host name of the deployment stage')
param hostName string


@description('The API settings')
param api object = {}

@description('The Monitoring settings')
param monitoring object = {
  enableApplicationInsights: false
  disableLocalAuth: false
  dailyCap: '1'
}

// === EXISTING ===

// Log Analytics Workspace
module workspace '../shared/existing/log-analytics-workspace.bicep' = if (monitoring.enableApplicationInsights) {
  name: 'Existing-LogAnalyticsWorkspace'
  scope: resourceGroup(monitoring.workspaceResourceGroup)
  params: {
    workspaceName: monitoring.workspaceName
  }
}

// === RESOURCES ===

// Application Insights
module ai '../shared/resources/app-insights.bicep' = if (monitoring.enableApplicationInsights) {
  name: 'Resource-ApplicationInsights'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    environmentName: environmentName
    hostName: hostName
    disableLocalAuth: monitoring.disableLocalAuth
    dailyCap: monitoring.dailyCap
    workspaceId: workspace.outputs.id
  }
}

// API Management
module apim '../shared/resources/api-management.bicep' = {
  name: 'Resource-ApiManagement'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    environmentName: environmentName
    hostName: hostName
    publisherEmail: api.publisherEmail
    publisherName: api.publisherName
    appInsightsName: ai.outputs.name
  }
}
