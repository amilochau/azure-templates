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
  Optional parameters:
    - `api`: {}
      - `publisherEmail`
      - `publisherName`
      - `products`: []
        - `productName`
        - `productDescription`
        - `subscriptionRequired`
        - `approvalRequired`
    - `monitoring`: {}
      - `enableApplicationInsights`
      - `disableLocalAuth`
      - `dailyCap`
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


@description('The API settings')
param api object = {
  publisherEmail: ''
  publisherName: ''
  products: []
}

@description('The Monitoring settings')
param monitoring object = {
  enableApplicationInsights: false
  dailyCap: '1'
}

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
module ai '../modules/monitoring/app-insights.bicep' = if (monitoring.enableApplicationInsights) {
  name: 'Resource-ApplicationInsights'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    disableLocalAuth: false
    dailyCap: monitoring.dailyCap
  }
}

// API Management instance
module apim '../modules/api-management/services.bicep' = {
  name: 'Resource-ApiManagementServices'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    publisherEmail: api.publisherEmail
    publisherName: api.publisherName
    appInsightsId: ai.outputs.id
    appInsightsInstrumentationKey: ai.outputs.instrumentationKey
    products: api.products
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
