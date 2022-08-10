/*
  Deploy infrastructure for Azure monitoring with Log Analytics
*/

// === PARAMETERS ===

@description('The organization name')
@minLength(3)
@maxLength(3)
param organizationName string

@description('The application name')
@minLength(2)
@maxLength(11)
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

@description('The deployment location')
param location string = resourceGroup().location

// === VARIABLES ===

@description('The region name')
var regionName = loadJsonContent('../modules/global/regions.json')[location].name

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

@description('Log Analytics Workspace')
module workspace '../modules/monitoring/log-analytics-workspace.bicep' = {
  name: 'Resource-LogAnalyticsWorkspace'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    pricingPlan: pricingPlan
  }
}

@description('Monitor Workbook - Applications')
module workbook_applications '../modules/monitoring/workbooks/applications.bicep' = {
  name: 'Resource-MonitorWorkbook-Applications'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
  }
}

@description('Monitor Workbook - Costs')
module workbook_costs '../modules/monitoring/workbooks/costs.bicep' = {
  name: 'Resource-MonitorWorkbook-Costs'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output resourceId string = workspace.outputs.id

@description('The Name of the deployed resource')
output resourceName string = workspace.outputs.name
