/*
  Reference an API with OpenAPI into API Management
*/

// === PARAMETERS ===

@description('The application name')
param applicationName string

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

// === EXISTING ===

@description('API Management')
resource apim 'Microsoft.ApiManagement/service@2021-01-01-preview' existing = {
  name: conventions.global.apiManagement.name
}

@description('API Management Products')
resource apimProducts 'Microsoft.ApiManagement/service/products@2021-01-01-preview' existing = [for (product, i) in products: {
  name: product
  parent: apim
}]

// === RESOURCES ===

@description('API Managment API version set')
resource apiVersionSet 'Microsoft.ApiManagement/service/apiVersionSets@2021-01-01-preview' = {
  name: conventions.naming.apiManagementApiVersionSet
  parent: apim
  properties: {
    displayName: applicationName
    versioningScheme: 'Segment'
    description: 'API version set for the "${applicationName}" application'
  }
}

@description('API Management API')
resource api 'Microsoft.ApiManagement/service/apis@2021-01-01-preview' = {
  name: conventions.naming.apiManagementApi
  parent: apim
  properties: {
    displayName: conventions.naming.apiManagementApi
    description: 'API for the "${applicationName}" application'
    path: applicationName
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

  resource policy 'policies@2021-01-01-preview' = {
    name: 'policy'
    properties: {
      format: 'xml'
      value: replace(loadTextContent('./local-api-policy.xml'), '%BACKEND_ID%', backendId)
    }
  }
}

@description('API Management Product API')
resource productApis 'Microsoft.ApiManagement/service/products/apis@2021-01-01-preview' = [for (product, i) in products: {
  name: api.name
  parent: apimProducts[i]
}]

// === OUTPUTS ===

@description('The ID of the deployed API Management API')
output id string = api.id

@description('The API Version of the deployed API Management API')
output apiVersion string = api.apiVersion

@description('The Name of the deployed API Management API')
output name string = api.name
