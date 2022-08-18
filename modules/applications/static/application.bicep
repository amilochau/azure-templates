/*
  Deploy a Static Web Apps application
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

@description('The Static Web app options')
param staticWebAppOptions object

@description('The deployment location')
param location string

// === VARIABLES ===

var swaSkuName = pricingPlan == 'Free' ? 'Free' : pricingPlan == 'Basic' ? 'Standard' : 'ERROR'
var swaSkuTier = pricingPlan == 'Free' ? 'Free' : pricingPlan == 'Basic' ? 'Standard' : 'ERROR'

// === RESOURCES ===

@description('Static Web Apps application')
resource swa 'Microsoft.Web/staticSites@2022-03-01' = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.staticWebApplication}'
  location: location
  tags: referential
  sku: {
    name: swaSkuName
    tier: swaSkuTier
  }
  properties: {
    stagingEnvironmentPolicy: 'Disabled'
    allowConfigFileUpdates: true
    buildProperties: {
      skipGithubActionWorkflowGeneration: true
    }
  }
}

@description('Custom domains for Static Web Apps')
module domains 'custom-domain.bicep' = [for (customDomain, i) in staticWebAppOptions.customDomains: if (contains(staticWebAppOptions, 'customDomains')) {
  name: 'Resource-CustomDomain-${customDomain}'
  params: {
    customDomain: customDomain
    swaName: swa.name
  }
}]

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = swa.id

@description('The API Version of the deployed resource')
output apiVersion string = swa.apiVersion

@description('The Name of the deployed resource')
output name string = swa.name

@description('The default host name of the deployed resource')
output defaultHostName string = !empty(swa.properties.customDomains) ? swa.properties.customDomains[0] : ''
