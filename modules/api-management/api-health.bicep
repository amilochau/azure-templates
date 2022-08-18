/*
  Reference an API for API Management health into API Management
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

// === VARIABLES ===

var apiPath = 'api/health'
var operationPolicy = loadTextContent('../global/api-policies/health.xml')

// === EXISTING ===

@description('API Management')
resource apim 'Microsoft.ApiManagement/service@2021-12-01-preview' existing = {
  name: conventions.global.apiManagement[referential.environment].name
}

// === RESOURCES ===

@description('API Management API')
resource api 'Microsoft.ApiManagement/service/apis@2021-12-01-preview' = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.apiManagementApi}-health'
  parent: apim
  properties: {
    displayName: '${conventions.naming.prefix}${conventions.naming.suffixes.apiManagementApi}-health'
    description: 'API for the API Management health'
    path: apiPath
    protocols: [
      'https'
    ]
    isCurrent: true
    apiRevision: '1'
    subscriptionRequired: false
  }

  resource operation 'operations' = {
    name: 'health-all'
    properties: {
      displayName: 'All health checks'
      method: 'GET'
      urlTemplate: '/'
      responses: [
        {
          statusCode: 200
        }
        {
          statusCode: 503
        }
      ]
    }

    resource policy 'policies' = {
      name: 'policy'
      properties: {
        format: 'rawxml'
        value: operationPolicy
      }
    }
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = api.id

@description('The API Version of the deployed resource')
output apiVersion string = api.apiVersion

@description('The Name of the deployed resource')
output name string = api.name
