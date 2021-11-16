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

@description('The GitHub repository URL')
param repositoryUrl string

@description('The GitHub repository branch')
param repositoryBranch string

@description('The application custom domains')
param customDomains array = []

// === VARIABLES ===

var location = resourceGroup().location
var swaSkuName = pricingPlan == 'Free' ? 'Free' : pricingPlan == 'Basic' ? 'Standard' : repositoryUrl // 'ERROR'
var swaSkuTier = pricingPlan == 'Free' ? 'Free' : pricingPlan == 'Basic' ? 'Standard' : repositoryBranch // 'ERROR'

// === RESOURCES ===

@description('Static Web Apps application')
resource swa 'Microsoft.Web/staticSites@2021-02-01' = {
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
    provider: 'GitHub' // This property is needed, the ARM documentation is not accurate
    repositoryUrl: repositoryUrl
    branch: repositoryBranch
    buildProperties: {
      skipGithubActionWorkflowGeneration: true
    }
  }
}

@description('Custom domains for Static Web Apps')
module domains 'custom-domain.bicep' = [for (customDomain, i) in customDomains: if (!empty(customDomains)) {
  name: 'Resource-CustomDomain-${customDomain}'
  params: {
    conventions: conventions
    customDomain: customDomain
    swaName: swa.name
    // isDefault: i == 0 // isDefault does not work on first deployment...
  }
}]

// === OUTPUTS ===

@description('The ID of the deployed Azure Static Web Apps')
output id string = swa.id

@description('The API Version of the deployed Azure Static Web Apps')
output apiVersion string = swa.apiVersion

@description('The Name of the deployed Azure Static Web Apps')
output name string = swa.name
