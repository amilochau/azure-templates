/*
  Deploy an API Management
  Resources deployed from this template:
    - API Management
  Required parameters:
    - `referential`
    - `publisherEmail`
    - `publisherName`
  Optional parameters:
    [None]
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The API publisher email')
@minLength(1)
param publisherEmail string

@description('The API publisher name')
@minLength(1)
param publisherName string

@description('The Application Insights ID')
param appInsightsId string

@description('The Application Insights instrumentation key')
param appInsightsInstrumentationKey string

@description('The Key Vault name')
param kvName string

// === VARIABLES ===

var location = resourceGroup().location
var apimName = '${referential.organization}-${referential.application}-${referential.host}-apim'
var apimLoggerKeyName = '${referential.organization}-${referential.application}-${referential.host}-apim-loggerkey'

// === EXISTING ===

// Key Vault
resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: kvName
}

// === RESOURCES ===

// Application Insights key into Key Vault
resource loggerKeySecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: apimLoggerKeyName
  parent: kv
  properties: {
    value: appInsightsInstrumentationKey
  }
}

// API Management
resource apim 'Microsoft.ApiManagement/service@2021-01-01-preview' = {
  name: apimName
  location: location
  sku: {
    name: 'Consumption'
    capacity: 0 // Needs to be at 0 for Consumption plan
  }
  identity: {
    type: 'SystemAssigned'
  }
  tags: referential
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': 'true'
    }
  }

  // Named value to store the Application Insights key
  resource loggerKey 'namedValues@2021-01-01-preview' = {
    name: apimLoggerKeyName
    dependsOn: [
      auth_apim_kv
    ]
    properties: {
      displayName: apimLoggerKeyName
      keyVault: {
        secretIdentifier: loggerKeySecret.properties.secretUri
      }
      secret: true
    }
  }

  // Logger
  resource logger 'loggers@2021-01-01-preview' = {
    name: 'logger-applicationinsights'
    dependsOn: [
      loggerKey
    ]
    properties: {
      loggerType: 'applicationInsights'
      description: 'API Management logger'
      resourceId: appInsightsId
      credentials: {
        'instrumentationKey': '{{${apimLoggerKeyName}}}'
      }
    }
  }

  // Diagnostic
  resource diagnostic 'diagnostics@2021-01-01-preview' = {
    name: 'applicationinsights'
    properties: {
      loggerId: logger.id
      alwaysLog: 'allErrors'
      sampling: {
        percentage: 100
        samplingType: 'fixed'
      }
    }
  }

  // Policy
  resource policy 'policies@2021-01-01-preview' = {
    name: 'policy'
    properties: {
      format: 'xml'
      value: loadTextContent('./assets/global-api-policy.xml')
    }
  }
}

// === AUTHORIZATIONS ===

// API Management to Key Vault
module auth_apim_kv '../authorizations/key-vault-secrets-user.bicep' = {
  name: 'Authorization-ApiManagement-KeyVault'
  params: {
    principalId: apim.identity.principalId
    keyVaultName: kv.name
  }
}

// === OUTPUTS ===

output id string = apim.id
output apiVersion string = apim.apiVersion
output name string = apim.name
