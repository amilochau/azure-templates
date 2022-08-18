/*
  Deploy infrastructure for Azure Functions application, with Application Insights, Key Vault, service bus and storage account resources, authorizations
*/

// === PARAMETERS ===

@description('The organization name')
@minLength(3)
@maxLength(3)
param organizationName string

@description('The application name')
@minLength(2)
@maxLength(13)
param applicationName string

@description('The host name of the deployment stage')
@minLength(3)
@maxLength(5)
param hostName string

@description('The azure-templates version')
@minLength(1)
param templateVersion string


@description('The pricing plan')
@allowed([
  'Free'    // The cheapest plan, can create some small fees
  'Basic'   // Basic use with default limitations
])
param pricingPlan string = 'Free'

@description('''
The Static Web app options:
- *customDomains*: string[]
''')
param staticWebAppOptions object

@description('The deployment location')
param location string = resourceGroup().location

// === VARIABLES ===

@description('The region name')
var regionName = loadJsonContent('../modules/global/regions.json')[location].name

@description('Global & naming conventions')
var conventions = json(replace(replace(replace(replace(loadTextContent('../modules/global/conventions.json'), '%ORGANIZATION%', organizationName), '%APPLICATION%', applicationName), '%HOST%', hostName), '%REGION%', regionName))

@description('Extended monitoring')
var extendedMonitoring = startsWith(hostName, 'prd')

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
    disableLocalAuth: false
    pricingPlan: pricingPlan
  }
}

@description('Static Web Apps application')
module swa '../modules/applications/static/application.bicep' = {
  name: 'Resource-StaticWebAppsApplication'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    pricingPlan: pricingPlan
    staticWebAppOptions: staticWebAppOptions
  }
}

@description('Availability tests on Static Web Apps application')
module webTest_swa '../modules/monitoring/web-tests/ui-availability.bicep' = if (extendedMonitoring) {
  name: 'Resource-AvailabilityTests-StaticWebApps'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    applicationInsightsId: ai.outputs.id
    applicationHostName: swa.outputs.defaultHostName
    
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output resourceId string = swa.outputs.id

@description('The Name of the deployed resource')
output resourceName string = swa.outputs.name
