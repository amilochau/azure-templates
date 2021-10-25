/*
  Deploy an Log Analytics Workspace
  Resources deployed from this template:
    - Log Analytics Workspace
  Required parameters:
    - `referential`
    - `conventions`
    - `pricingPlan`
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

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The pricing plan')
@allowed([
  'Free'    // The cheapest plan, can create some small fees
  'Basic'   // Basic use with default limitations
])
param pricingPlan string

// === VARIABLES ===

var location = resourceGroup().location
var dailyCap = pricingPlan == 'Free' ? '0.1' : pricingPlan == 'Basic' ? '100' : 'ERROR' // in GB/d

// === RESOURCES ===

@description('// Log Analytics Workspace')
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: conventions.naming.logAnalyticsWorkspace.name
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
