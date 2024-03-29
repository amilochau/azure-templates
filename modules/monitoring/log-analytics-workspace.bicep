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

@description('The deployment location')
param location string

// === VARIABLES ===

var dailyCap = pricingPlan == 'Free' ? '0.1' : pricingPlan == 'Basic' ? '100' : 'ERROR' // in GB/d

// === RESOURCES ===

@description('Log Analytics Workspace')
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.logAnalyticsWorkspace}'
  location: location
  tags: referential
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: any(dailyCap)
    }
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = workspace.id

@description('The API Version of the deployed resource')
output apiVersion string = workspace.apiVersion

@description('The Name of the deployed resource')
output name string = workspace.name
