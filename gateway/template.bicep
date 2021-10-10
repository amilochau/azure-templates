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
    - `environmentName`
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
      - `workspaceName`
      - `workspaceResourceGroup`
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

@description('The environment name of the deployment stage')
@allowed([
  'Development'
  'Staging'
  'Production'
])
param environmentName string

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
  disableLocalAuth: false
  dailyCap: '1'
}

// === EXISTING ===

// Log Analytics Workspace
module workspace '../modules/existing/log-analytics-workspace.bicep' = if (monitoring.enableApplicationInsights) {
  name: 'Existing-LogAnalyticsWorkspace'
  scope: resourceGroup(monitoring.enableApplicationInsights ? monitoring.workspaceResourceGroup : '')
  params: {
    workspaceName: monitoring.workspaceName
  }
}

// === RESOURCES ===

// Tags
module tags '../modules/resources/tags.bicep' = {
  name: 'Resource-Tags'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    environmentName: environmentName
    hostName: hostName
  }
}

// Key Vault
module kv '../modules/resources/key-vault/vault.bicep' = {
  name: 'Resource-KeyVault'
  params: {
    referential: tags.outputs.referential
  }
}

// Application Insights
module ai '../modules/resources/app-insights.bicep' = if (monitoring.enableApplicationInsights) {
  name: 'Resource-ApplicationInsights'
  params: {
    referential: tags.outputs.referential
    disableLocalAuth: monitoring.disableLocalAuth
    dailyCap: monitoring.dailyCap
    workspaceId: workspace.outputs.id
  }
}

// API Management instance
module apim '../modules/resources/api-management/services.bicep' = {
  name: 'Resource-ApiManagementServices'
  params: {
    referential: tags.outputs.referential
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
