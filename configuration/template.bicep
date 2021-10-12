/*
  Deploy infrastructure for Azure App Configuration
  Resources deployed from this template:
    - App Configuration
  Required parameters:
    - `organizationName`
    - `applicationName`
    - `hostName`
  Optional parameters:
    - `pricingPlan`
  Outputs:
    [None]
*/

// === PARAMETERS ===

@description('The organization name')
@minLength(3)
@maxLength(3)
param organizationName string

@description('The application name')
@minLength(3)
@maxLength(12)
param applicationName string

@description('The host name of the deployment stage')
@minLength(3)
@maxLength(5)
param hostName string


@description('The pricing plan')
@allowed([
  'Free'    // The cheapest plan, can create some small fees
  'Basic'   // Basic use with default limitations
])
param pricingPlan string = 'Free'

// === VARIABLES ===

var conventions = json(replace(replace(replace(loadTextContent('../modules/global/conventions.json'), '%ORGANIZATION', organizationName), '%APPLICATION%', applicationName), '%HOST%', hostName))

// === RESOURCES ===

// Tags
module tags '../modules/global/tags.bicep' = {
  name: 'Resource-Tags'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    hostName: hostName
  }
}

module appConfig '../modules/configuration/app-config.bicep' = {
  name: 'Resource-AppConfiguration'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    pricingPlan: pricingPlan
  }
}
