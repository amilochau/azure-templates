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
param apiVersion string = 'v1'

@description('Whether a subscription is required')
param subscriptionRequired bool = true

// === EXISTING ===

// API Management
resource apim 'Microsoft.ApiManagement/service@2021-01-01-preview' existing = {
  name: conventions.global.apiManagement.name
}

// === RESOURCES ===

// API Managment API version set
resource apim_apiversionset 'Microsoft.ApiManagement/service/apiVersionSets@2021-01-01-preview' = {
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
    apiVersionSetId: apim_apiversionset.id
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

// === OUTPUTS ===

output id string = api.id
output apiVersion string = api.apiVersion
output name string = api.name
