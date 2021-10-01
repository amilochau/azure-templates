/*
  Reference an API with OpenAPI into API Management
  Resources deployed from this template:
    - API Management children objects
  Required parameters:
    - `referential`
    - `apiManagementName`
    - `apiName`
    - `apiOpenApiLink`
  Optional parameters:
    - `apiVersion`
    - `subscriptionRequired`
  Outputs:
    [None]
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The API Management name')
param apiManagementName string

@description('The API name')
param apiName string

@description('The OpenAPI link for the API')
param apiOpenApiLink string

@description('The API version')
param apiVersion string = 'v1'

@description('Whether a subscription is required')
param subscriptionRequired bool = true

// === VARIABLES ===

var apimApiVersionSetName = '${referential.organization}-${referential.application}-${referential.host}-apimversionset'
var apimApiName = '${referential.organization}-${referential.application}-${referential.host}-apimapi'

// === RESOURCES ===

// API Managment API version set
resource apim_apiversionset 'Microsoft.ApiManagement/service/apiVersionSets@2021-01-01-preview' = {
  name: '${apiManagementName}/${apimApiVersionSetName}'
  properties: {
    displayName: referential.application
    versioningScheme: 'Segment'
    description: 'API version set for the "${apiName}" application'
  }
}

// API Management API
resource apim_api 'Microsoft.ApiManagement/service/apis@2021-01-01-preview' = {
  name: '${apiManagementName}/${apimApiName}'
  properties: {
    displayName: apimApiName
    description: 'API for the "${apiName}" application'
    path: referential.application
    protocols: [
      'https'
    ]
    isCurrent: true
    apiVersion: apiVersion
    apiRevision: '1'
    apiVersionSetId: apim_apiversionset.id
    subscriptionRequired: subscriptionRequired

    format: 'openapi+json'
    value: loadTextContent('./../assets/swagger.json')
  }
}
