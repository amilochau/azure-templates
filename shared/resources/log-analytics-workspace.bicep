// Deploy an Log Analytics Workspace
// Resources deployed from this template:
//   - Log Analytics Workspace
// Required parameters:
//   - `organizationName`
//   - `applicationName`
//   - `environmentName`
//   - `hostName`
//   - `dailyCap`
// Optional parameters:
//   [None]
// Outputs:
//   - `id`
//   - `apiVersion`
//   - `name`

// === PARAMETERS ===

@description('The organization name')
param organizationName string

@description('The application name')
param applicationName string

@description('The environment name of the deployment stage')
param environmentName string

@description('The host name of the deployment stage')
param hostName string


@description('Daily data ingestion cap, in GB/d')
param dailyCap string

// === VARIABLES ===

var location = resourceGroup().location
var workspaceName = '${organizationName}-${applicationName}-${hostName}-ws'

// === RESOURCES ===

// Log Analytics Workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: workspaceName
  location: location
  tags:{
    organization: organizationName
    application: applicationName
    environment: environmentName
    host: hostName
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: json(dailyCap)
    }
  }
}

// === OUTPUTS ===

output id string = workspace.id
output apiVersion string = workspace.apiVersion
output name string = workspace.name
