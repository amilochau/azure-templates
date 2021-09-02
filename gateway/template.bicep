/*
  Deploy infrastructure for API Management
  Resources deployed from this template:
    - API Management
    - Application Insights
  Required parameters:
    - `organizationName`
    - `applicationName`
    - `environmentName`
    - `hostName`
  Optional parameters:
    - `api`: {}
      - `publisherEmail`
      - `publisherName`
    - `monitoring`: {}
      - `enableApplicationInsights`
      - `disableLocalAuth`
      - `dailyCap`
      - `workspaceName`
      - `workspaceResourceGroup`
  Outputs:
    [None]
*/

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
module workspace '../modules/existing/log-analytics-workspace.bicep' = if (monitoring.enableApplicationInsights) {
  name: 'Existing-LogAnalyticsWorkspace'
  scope: resourceGroup(monitoring.workspaceResourceGroup)
  params: {
    workspaceName: monitoring.workspaceName
  }
}

// === RESOURCES ===

// Tags
module tags '../modules/resources/tags.bicep' = {
  name: 'Resource-Tags'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    environmentName: environmentName
    hostName: hostName
  }
}

// Application Insights
module ai '../modules/resources/app-insights.bicep' = if (monitoring.enableApplicationInsights) {
  name: 'Resource-ApplicationInsights'
  params: {
    referential: tags.outputs.referential
    disableLocalAuth: monitoring.disableLocalAuth
    dailyCap: monitoring.dailyCap
    workspaceId: workspace.outputs.id
  }
}

// API Management
module apim '../modules/resources/api-management.bicep' = {
  name: 'Resource-ApiManagement'
  params: {
    referential: tags.outputs.referential
    publisherEmail: api.publisherEmail
    publisherName: api.publisherName
    appInsightsId: ai.outputs.id
    appInsightsInstrumentationKey: ai.outputs.instrumentationKey
  }
}
