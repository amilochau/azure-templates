/*
  Deploy infrastructure for API Management, with its Key Vault, services and products, authorizations
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

@description('The API publisher name')
@minLength(1)
param apiPublisherName string

@description('The API publisher email')
@minLength(1)
param apiPublisherEmail string

@description('The API products')
param apiProducts array = []

@description('The deployment location')
param location string = resourceGroup().location

// === VARIABLES ===

@description('The region name')
var regionName = json(loadTextContent('../modules/global/regions.json'))[location]

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

@description('Key Vault')
module kv '../modules/configuration/key-vault.bicep' = {
  name: 'Resource-KeyVault'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
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

@description('API Management instance')
module apim '../modules/api-management/services.bicep' = {
  name: 'Resource-ApiManagementServices'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    location: location
    publisherEmail: apiPublisherEmail
    publisherName: apiPublisherName
    appInsightsId: ai.outputs.id
    appInsightsInstrumentationKey: ai.outputs.instrumentationKey
    products: apiProducts
  }
}

// === AUTHORIZATIONS ===

@description('API Management to Key Vault')
module auth_apim_kv '../modules/authorizations/key-vault-secrets-user.bicep' = {
  name: 'Authorization-ApiManagement-KeyVault'
  params: {
    principalId: apim.outputs.principalId
    keyVaultName: kv.outputs.name
    roleDescription: 'API Management should read the secrets from Key Vault to use secret named values'
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output resourceId string = apim.outputs.id

@description('The Name of the deployed resource')
output resourceName string = apim.outputs.name
