/*
  Reference an API with OpenAPI into API Management
*/

// === PARAMETERS ===

@description('The application name')
param applicationName string

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The API Management backend ID')
param backendId string

@description('The API version')
param apiVersion string

@description('Whether a subscription is required')
param subscriptionRequired bool

@description('The products to link with the API Management API')
param products array

@description('The OpenAPI specification link')
param openApiLink string

@description('The OpenID configuration for authentication')
param openIdConfiguration object

// === VARIABLES ===

var enableOpenId = contains(openIdConfiguration, 'endpoint') && contains(openIdConfiguration, 'apiClientId')
var apiPath = endsWith(applicationName, 'api') ? substring(applicationName, 0, length(applicationName) - 3) : applicationName
var anonymousUrlRegex = contains(openIdConfiguration, 'gatewayAnonymousUrlRegex') ? openIdConfiguration.gatewayAnonymousUrlRegex : ''
var apiPolicy = enableOpenId ? replace(replace(replace(replace(
    loadTextContent('../global/api-policies/local-jwt.xml'),
    '%BACKEND_ID%', backendId),
    '%OPENID_CONFIG_ENDPOINT%', openIdConfiguration.endpoint),
    '%API_CLIENT_ID%', openIdConfiguration.apiClientId),
    '%ANONYMOUS_URL_REGEX%', '"${anonymousUrlRegex}"'
  ) : replace(
    loadTextContent('../global/api-policies/local-simple.xml'),
    '%BACKEND_ID%', backendId
  )

// === EXISTING ===

@description('API Management')
resource apim 'Microsoft.ApiManagement/service@2021-01-01-preview' existing = {
  name: conventions.global.apiManagement[referential.environment].name
}

@description('API Management Products')
resource apimProducts 'Microsoft.ApiManagement/service/products@2021-01-01-preview' existing = [for (product, i) in products: {
  name: product
  parent: apim
}]

// === RESOURCES ===

@description('API Managment API version set')
resource apiVersionSet 'Microsoft.ApiManagement/service/apiVersionSets@2021-01-01-preview' = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.apiManagementApiVersionSet}'
  parent: apim
  properties: {
    displayName: applicationName
    versioningScheme: 'Segment'
    description: 'API version set for the "${applicationName}" application'
  }
}

@description('API Management API')
resource api 'Microsoft.ApiManagement/service/apis@2021-01-01-preview' = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.apiManagementApi}'
  parent: apim
  properties: {
    displayName: '${conventions.naming.prefix}${conventions.naming.suffixes.apiManagementApi}'
    description: 'API for the "${applicationName}" application'
    path: apiPath
    protocols: [
      'https'
    ]
    isCurrent: true
    apiVersion: apiVersion
    apiRevision: '1'
    apiVersionSetId: apiVersionSet.id
    subscriptionRequired: subscriptionRequired

    // OpenAPI specifications from a link
    format: 'openapi+json-link'
    value: openApiLink
  }

  resource policy 'policies' = {
    name: 'policy'
    properties: {
      format: 'xml'
      value: apiPolicy
    }
  }
}

@description('API Management Product API')
resource productApis 'Microsoft.ApiManagement/service/products/apis@2021-01-01-preview' = [for (product, i) in products: {
  name: api.name
  parent: apimProducts[i]
}]

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = api.id

@description('The API Version of the deployed resource')
output apiVersion string = api.apiVersion

@description('The Name of the deployed resource')
output name string = api.name
