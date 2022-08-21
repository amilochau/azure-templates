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

@description('The Application Insights instrumentation key')
param appInsightsInstrumentationKey string

@description('The API Management publisher email')
param publisherEmail string

@description('The API Management publisher name')
param publisherName string

@description('The API Management products')
param products array

@description('The custom domains for the gateway')
param gatewayCustomDomains array

@description('The deployment location')
param location string

// === VARIABLES ===

var apimLoggerKeyName = '${conventions.naming.prefix}${conventions.naming.suffixes.apiManagement}-loggerkey'
var apimPolicy = loadTextContent('../global/api-policies/global.xml')
var hostNameConfigurations = [for gatewayCustomDomain in gatewayCustomDomains: {
  type: 'Proxy'
  hostName: gatewayCustomDomain
  certificateSource: 'Managed'
  negotiateClientCertificate: false
  defaultSslBinding: true
}]

// === RESOURCES ===

@description('Custom domains for API Management gateways')
module domains './custom-domain.bicep' = [for customDomain in gatewayCustomDomains: {
  name: 'Resource-CnameRecord-${customDomain}'
  params: {
    customDomain: customDomain
    apiManagementUrl: '${conventions.naming.prefix}${conventions.naming.suffixes.apiManagementGatewayHost}'
  }
}]

@description('API Management services')
resource apim 'Microsoft.ApiManagement/service@2021-12-01-preview' = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.apiManagement}'
  location: location
  dependsOn: [
    domains
  ]
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
    hostnameConfigurations: union([{
      type: 'Proxy'
      certificateSource: 'BuiltIn'
      hostName: '${conventions.naming.prefix}${conventions.naming.suffixes.apiManagementGatewayHost}'
      defaultSslBinding: false
    }], hostNameConfigurations)
  }

  // Named value to store the Application Insights instrumentation key
  resource loggerKey 'namedValues' = {
    name: apimLoggerKeyName
    properties: {
      displayName: apimLoggerKeyName
      value: appInsightsInstrumentationKey
    }
  }

  // Logger
  resource logger 'loggers' = {
    name: 'logger-applicationinsights'
    properties: {
      loggerType: 'applicationInsights'
      description: 'API Management logger'
      resourceId: appInsightsId
      credentials: {
        instrumentationKey: '{{${loggerKey.name}}}'
      }
    }
  }

  // Diagnostic
  resource diagnostic 'diagnostics' = {
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
  resource policy 'policies' = {
    name: 'policy'
    properties: {
      format: 'xml'
      value: apimPolicy
    }
  }

  // Products
  resource apimProducts 'products' = [for product in products: {
    name: product.productName
    properties: {
      displayName: product.productName
      description: product.productDescription
      subscriptionRequired: product.subscriptionRequired
      approvalRequired: product.subscriptionRequired ? product.approvalRequired : null
      state: 'published'
    }
  }]
}

@description('The API for API Management health')
module apiHealth 'api-health.bicep' = {
  name: 'Resource-ApiHealth'
  params: {
    referential: referential
    conventions: conventions
  }
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


output hostnameConfigurations array = apim.properties.hostnameConfigurations
output gatewayUrl string = apim.properties.gatewayUrl
output customProperties object = apim.properties.customProperties
