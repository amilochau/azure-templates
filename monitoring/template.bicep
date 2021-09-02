/*
  Deploy infrastructure for Azure monitoring
  Resources deployed from this template:
    - Log Analytics Workspace
  Required parameters:
    - `organizationName`
    - `applicationName`
    - `environmentName`
    - `hostName`
  Optional parameters:
    - `dailyCap`
  Outputs:
    [None]
*/

// === PARAMETERS ===

@description('The organization name')
@minLength(3)
@maxLength(3)
param organizationName string

@description('The application name')
@minLength(3)
@maxLength(12)
param applicationName string

@description('The environment name of the deployment stage')
@allowed([
  'Development'
  'Staging'
  'Production'
])
param environmentName string

@description('The host name of the deployment stage')
@minLength(3)
@maxLength(5)
param hostName string


@description('The daily cap for Log Analytics data ingestion')
param dailyCap string = '1'

// === RESOURCES ===

// Tags
module tags '../shared/resources/tags.bicep' = {
  name: 'Resource-Tags'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    environmentName: environmentName
    hostName: hostName
  }
}

// Log Analytics Workspace
module workspace '../shared/resources/log-analytics-workspace.bicep' = {
  name: 'Resource-LogAnalyticsWorkspace'
  params: {
    referential: tags.outputs.referential
    dailyCap: dailyCap
  }
}
