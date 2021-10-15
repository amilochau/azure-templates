/*
  Reference an API with OpenAPI into API Management
  Resources deployed from this template:
    - API Management children objects
  Required parameters:
    - `referential`
    - `conventions`
    - `backendId`
  Optional parameters:
    - `apiVersion`
    - `subscriptionRequired`
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
*/

// === PARAMETERS ===

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

// === EXISTING ===

// API Management
resource apim 'Microsoft.ApiManagement/service@2021-01-01-preview' existing = {
  name: conventions.global.apiManagementName
}

// API Management Products
resource apimProducts 'Microsoft.ApiManagement/service/products@2021-01-01-preview' existing = [for (product, i) in products: {
  name: product
  parent: apim
}]

// === RESOURCES ===

// API Managment API version set
resource apiVersionSet 'Microsoft.ApiManagement/service/apiVersionSets@2021-01-01-preview' = {
  name: conventions.naming.apiManagement.apiVersionSetName
  parent: apim
  properties: {
    displayName: referential.application
    versioningScheme: 'Segment'
    description: 'API version set for the "${referential.application}" application'
  }
}

// API Management API
resource api 'Microsoft.ApiManagement/service/apis@2021-01-01-preview' = {
  name: conventions.naming.apiManagement.apiName
  parent: apim
  properties: {
    displayName: conventions.naming.apiManagement.apiName
    description: 'API for the "${referential.application}" application'
    path: referential.application
    protocols: [
      'https'
    ]
    isCurrent: true
    apiVersion: apiVersion
    apiRevision: '1'
    apiVersionSetId: apiVersionSet.id
    subscriptionRequired: subscriptionRequired
  }

  resource policy 'policies@2021-01-01-preview' = {
    name: 'policy'
    properties: {
      format: 'xml'
      value: replace(loadTextContent('./local-api-policy.xml'), '%BACKEND_ID%', backendId)
    }
  }
}

// API Management Product API
resource productApis 'Microsoft.ApiManagement/service/products/apis@2021-01-01-preview' = [for (product, i) in products: {
  name: api.name
  parent: apimProducts[i]
}]

// === OUTPUTS ===

output id string = api.id
output apiVersion string = api.apiVersion
output name string = api.name
