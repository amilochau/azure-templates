/*
  Deploy an API Management with its services and products
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The Application Insights ID')
param appInsightsId string

@description('The Application Insights connection string')
param appInsightsConnectionString string

@description('The API Management publisher email')
param publisherEmail string

@description('The API Management publisher name')
param publisherName string

@description('The API Management products')
param products array

@description('The deployment location')
param location string

// === VARIABLES ===

var apimLoggerKeyName = '${conventions.naming.prefix}${conventions.naming.suffixes.apiManagement}-loggerkey'

// === RESOURCES ===

@description('API Management services')
resource apim 'Microsoft.ApiManagement/service@2021-01-01-preview' = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.apiManagement}'
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

  // Named value to store the Application Insights connection string
  resource loggerKey 'namedValues@2021-01-01-preview' = {
    name: apimLoggerKeyName
    properties: {
      displayName: apimLoggerKeyName
      value: appInsightsConnectionString
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
        'instrumentationKey': '{{${loggerKey.name}}}' !!
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
      value: loadTextContent('./global-api-policy.xml')
    }
  }

  // Products
  resource apimProducts 'products@2021-01-01-preview' = [for product in products: {
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

@description('The ID of the deployed resource')
output id string = apim.id

@description('The API Version of the deployed resource')
output apiVersion string = apim.apiVersion

@description('The Name of the deployed resource')
output name string = apim.name

@description('The Principal ID of the deployed resource')
output principalId string = apim.identity.principalId
