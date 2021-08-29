// Deploy an Log Analytics Workspace
// Resources deployed from this template:
//   - Log Analytics Workspace
// Required parameters:
//   - `dailyCap`
// Optional parameters:
//   [None]
// Outputs:
//   - `id`
//   - `apiVersion`
//   - `name`

// === PARAMETERS ===

@description('Daily data ingestion cap, in GB/d')
param dailyCap string

// === VARIABLES ===

var location = resourceGroup().location
var tags = resourceGroup().tags
var workspaceName = '${tags.organization}-${tags.application}-${tags.host}-ws'

// === RESOURCES ===

// Log Analytics Workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: workspaceName
  location: location
  tags: resourceGroup().tags
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
