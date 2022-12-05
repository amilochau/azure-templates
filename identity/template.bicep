/*
  Deploy infrastructure for identit with AAD B2C
*/

// === PARAMETERS ===

@description('The organization name')
@minLength(3)
@maxLength(3)
param organizationName string

@description('The application name')
@minLength(2)
@maxLength(14)
param applicationName string

@description('The host name of the deployment stage')
@minLength(3)
@maxLength(5)
param hostName string

@description('The ARM templates version')
@minLength(1)
param templateVersion string


@description('The name of the tenant')
#disable-next-line no-unused-params
param tenantName string

@description('The pricing plan')
@allowed([
  'Free'    // The cheapest plan, can create some small fees
  'Basic'   // Basic use with default limitations
])
param pricingPlan string = 'Free'

@description('The deployment location')
param location string = resourceGroup().location

// === VARIABLES ===

@description('The region name')
var regionName = loadJsonContent('../modules/global/regions.json')[location].name

//@description('The region name')
//var regionAadB2c = loadJsonContent('../modules/global/regions.json')[location]['aad-b2c']

@description('Global & naming conventions')
var conventions = json(replace(replace(replace(replace(loadTextContent('../modules/global/conventions.json'), '%ORGANIZATION%', organizationName), '%APPLICATION%', applicationName), '%HOST%', hostName), '%REGION%', regionName))

// === RESOURCES ===

@description('Resource groupe tags')
module tags '../modules/global/tags.bicep' = {
  name: 'Resource-Tags'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    hostName: hostName
    regionName: regionName
    templateVersion: templateVersion
  }
}

@description('Application Insights')
module ai '../modules/monitoring/app-insights.bicep' = {
  name: 'Resource-ApplicationInsights'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    disableLocalAuth: false // We use AI from templates where we define intrumentation key explicitely
    pricingPlan: pricingPlan
  }
}

/* Module disabled as B2C tenant can't be deployed with ARM templates yet
@description('AAD B2C')
module b2c '../modules/identity/b2c.bicep' = {
  name: 'Resource-B2CDirectory'
  params: {
    referential: tags.outputs.referential
    location: regionAadB2c
    tenantName: tenantName
  }
}
*/

// === OUTPUTS ===

@description('The ID of the deployed resource')
output resourceId string = ai.outputs.id

@description('The Name of the deployed resource')
output resourceName string = ai.outputs.name
