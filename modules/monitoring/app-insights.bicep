/*
  Deploy an Application Insights
  Resources deployed from this template:
    - Application Insights
  Required parameters:
    - `referential`
    - `conventions`
    - `pricingPlan`
    - `disableLocalAuth`
  Optional parameters:
    [None]
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
    - `instrumentationKey`
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

// === VARIABLES ===

var location = resourceGroup().location
var dailyCap = pricingPlan == 'Free' ? '0.1' : pricingPlan == 'Basic' ? '100' : 'ERROR' // in GB/d

// === RESOURCES ===

@description('Log Analytics Workspace')
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  scope: resourceGroup(conventions.global.logAnalyticsWorkspace.resourceGroupName)
  name: conventions.global.logAnalyticsWorkspace.name
}

@description('Application Insights')
resource ai 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: conventions.naming.applicationInsights.name
  location: location
  kind: 'web'
  tags: referential
  properties: {
    Application_Type: 'web'
    DisableLocalAuth: disableLocalAuth
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

output id string = ai.id
output apiVersion string = ai.apiVersion
output name string = ai.name
output instrumentationKey string = ai.properties.InstrumentationKey
