/*
  Deploy an Log Analytics Workspace
  Resources deployed from this template:
    - Log Analytics Workspace
  Required parameters:
    - `referential`
    - `workspaceName`
    - `dailyCap`
  Optional parameters:
    [None]
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The Log Analytics workspace name')
param workspaceName string

@description('Daily data ingestion cap, in GB/d')
param dailyCap string

// === VARIABLES ===

var location = resourceGroup().location

// === RESOURCES ===

// Log Analytics Workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: workspaceName
  location: location
  tags: referential
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
