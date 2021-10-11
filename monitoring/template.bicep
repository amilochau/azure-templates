/*
  Deploy infrastructure for Azure monitoring
  Resources deployed from this template:
    - Log Analytics Workspace
  Required parameters:
    - `organizationName`
    - `applicationName`
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

@description('The host name of the deployment stage')
@minLength(3)
@maxLength(5)
param hostName string


@description('The daily cap for Log Analytics data ingestion')
param dailyCap string = '1'

// === VARIABLES ===

var conventions = json(replace(replace(replace(loadTextContent('../modules/global/conventions.json'), '%ORGANIZATION', organizationName), '%APPLICATION%', applicationName), '%HOST%', hostName))

// === RESOURCES ===

// Tags
module tags '../modules/global/tags.bicep' = {
  name: 'Resource-Tags'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    hostName: hostName
  }
}

// Log Analytics Workspace
module workspace '../modules/monitoring/log-analytics-workspace.bicep' = {
  name: 'Resource-LogAnalyticsWorkspace'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    dailyCap: dailyCap
  }
}
