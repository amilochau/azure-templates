// Deploy infrastructure for Azure monitoring
// Resources deployed from this template:
//   - Log Analytics Workspace
// Required parameters:
//   - `organizationPrefix`
//   - `applicationName`
//   - `environmentName`
//   - `hostName`
// Optional parameters:
//   - `dailyCap`
// Outputs:
//   [None]

// === PARAMETERS ===

@description('The organization prefix')
@minLength(3)
@maxLength(3)
param organizationPrefix string // @todo @next-major-version To be renamed as organizationName

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

// === VARIABLES ===

var workspaceName = '${organizationPrefix}-ws-${applicationName}-${hostName}'

// === RESOURCES ===

// Log Analytics Workspace
module workspace '../shared/log-analytics-workspace.bicep' = {
  name: workspaceName
  params: {
    workspaceName: workspaceName
    dailyCap: dailyCap
  }
}
