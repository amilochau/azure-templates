/*
  Deploy a Log Analytics Workspace
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

@description('The ID of the deployed Log Analytics Workspace')
output id string = workspace.id

@description('The API Version of the deployed Log Analytics Workspace')
output apiVersion string = workspace.apiVersion

@description('The Name of the deployed Log Analytics Workspace')
output name string = workspace.name
