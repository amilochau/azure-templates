/*
  Deploy an API Management
  Resources deployed from this template:
    - API Management services and products
  Required parameters:
    - `referential`
    - `publisherEmail`
    - `publisherName`
    - `appInsightsId`
    - `appInsightsInstrumentationKey`
  Optional parameters:
    - `products`: []
      - `productName`
      - `productDescription`
      - `subscriptionRequired`
      - `approvalRequired`
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
    - `principalId`
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The API Management publisher email')
@minLength(1)
param publisherEmail string

@description('The API Management publisher name')
@minLength(1)
param publisherName string

@description('The Application Insights ID')
param appInsightsId string

@description('The Application Insights instrumentation key')
param appInsightsInstrumentationKey string

@description('The API Management products')
param products array = []

// === VARIABLES ===

var location = resourceGroup().location
var apimName = '${referential.organization}-${referential.application}-${referential.host}-apim'
var apimLoggerKeyName = '${referential.organization}-${referential.application}-${referential.host}-apim-loggerkey'

// === RESOURCES ===

// API Management services
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
    properties: {
      displayName: apimLoggerKeyName
      value: appInsightsInstrumentationKey
      secret: true
    }
  }

  // Logger
  resource logger 'loggers@2021-01-01-preview' = {
    name: 'logger-applicationinsights'
    properties: {
      loggerType: 'applicationInsights'
      description: 'API Management logger'
      resourceId: appInsightsId
      credentials: {
        'instrumentationKey': '{{${loggerKey.name}}}'
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
      value: loadTextContent('./../assets/global-api-policy.xml')
    }
  }

  // Products
  resource apim_products 'products@2021-01-01-preview' = [for product in products: {
    name: product.productName
    properties: {
      displayName: product.productName
      description: product.productDescription
      subscriptionRequired: product.subscriptionRequired
      approvalRequired: product.approvalRequired
      state: 'published'
    }
  }]
}

// === OUTPUTS ===

output id string = apim.id
output apiVersion string = apim.apiVersion
output name string = apim.name
output principalId string = apim.identity.principalId
