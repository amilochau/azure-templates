/*
  Deploy infrastructure for API Management
  Resources deployed from this template:
    - API Management
    - Application Insights
    - Key Vault
    - Authorizations
  Required parameters:
    - `organizationName`
    - `applicationName`
    - `hostName`
    - `apiPublisherName`
    - `apiPublisherEmail`
  Optional parameters:
    - `pricingPlan`
    - `apiProducts`: []
      - `productName`
      - `productDescription`
      - `subscriptionRequired`
      - `approvalRequired`
    - `disableApplicationInsights`
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

@description('The API publisher name')
param apiPublisherName string

@description('The API publisher email')
param apiPublisherEmail string

@description('The API products')
param apiProducts array = []

@description('Whether to disable the Application Insights')
param disableApplicationInsights bool = false

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

// Key Vault
module kv '../modules/configuration/key-vault.bicep' = {
  name: 'Resource-KeyVault'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
  }
}

// Application Insights
module ai '../modules/monitoring/app-insights.bicep' = if (!disableApplicationInsights) {
  name: 'Resource-ApplicationInsights'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    disableLocalAuth: false
    pricingPlan: pricingPlan
  }
}

// API Management instance
module apim '../modules/api-management/services.bicep' = {
  name: 'Resource-ApiManagementServices'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    publisherEmail: apiPublisherEmail
    publisherName: apiPublisherName
    appInsightsId: ai.outputs.id
    appInsightsInstrumentationKey: ai.outputs.instrumentationKey
    products: apiProducts
  }
}

// === AUTHORIZATIONS ===

// API Management to Key Vault
module auth_apim_kv '../modules/authorizations/key-vault-secrets-user.bicep' = {
  name: 'Authorization-ApiManagement-KeyVault'
  params: {
    principalId: apim.outputs.principalId
    keyVaultName: kv.outputs.name
  }
}
