/*
  Deploy an Application Insights
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

@description('Disable non-AAD based authentication to publish metrics')
param disableLocalAuth bool = false

@description('The deployment location')
param location string

// === VARIABLES ===

var dailyCap = pricingPlan == 'Free' ? '0.1' : pricingPlan == 'Basic' ? '100' : 'ERROR' // in GB/d

// === RESOURCES ===

@description('Log Analytics Workspace')
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  scope: resourceGroup(conventions.global.logAnalyticsWorkspace[referential.environment].resourceGroupName)
  name: conventions.global.logAnalyticsWorkspace[referential.environment].name
}

@description('Application Insights')
resource ai 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.applicationInsights}'
  location: location
  kind: 'web'
  tags: referential
  properties: {
    Application_Type: 'web'
    DisableLocalAuth: disableLocalAuth // true = Enforcing AAD as the only authentication method
    /* One main limitation to put this 'DisableLocalAuth' settings to 'true':
      1/ Functions application do not support RBAC authentication yet
    */
    WorkspaceResourceId: workspace.id
  }

  resource featuresCapabilities 'pricingPlans@2017-10-01' = {
    name: 'current'
    properties: {
      cap: json(dailyCap)
      planType: 'Basic'
    }
  }
}

// === OUTPUTS ===

@description('The ID of the deployed Application Insights')
output id string = ai.id

@description('The API Version of the deployed Application Insights')
output apiVersion string = ai.apiVersion

@description('The Name of the deployed Application Insights')
output name string = ai.name

@description('The Instrumentation Key of the deployed Application Insights')
output instrumentationKey string = ai.properties.InstrumentationKey
