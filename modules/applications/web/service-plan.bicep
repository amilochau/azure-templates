/*
  Deploy a Service Plan
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

var servicePlanSkuName = pricingPlan == 'Free' ? 'F1' : pricingPlan == 'Basic' ? 'B1' : 'ERROR'
var servicePlanSkuTier = pricingPlan == 'Free' ? 'Free' : pricingPlan == 'Basic' ? 'Basic' : 'ERROR'

// === RESOURCES ===

@description('Service Plan')
resource servicePlan 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.servicePlan}'
  location: location
  sku: {
    name: servicePlanSkuName
    tier: servicePlanSkuTier
  }
  kind: 'app,linux,container'
  tags: referential
  properties: {
    reserved: true // Linux App Service
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = servicePlan.id

@description('The API Version of the deployed resource')
output apiVersion string = servicePlan.apiVersion

@description('The Name of the deployed resource')
output name string = servicePlan.name
