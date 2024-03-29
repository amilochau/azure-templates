/*
  Deploy an API Management backend
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The resource ID')
param resourceId string

@description('The backend name')
param backendName string

@description('The backend URL')
param backendUrl string

@description('The backend credentials')
param credentials object = {}

// === EXISTING ===

@description('API Management')
resource apim 'Microsoft.ApiManagement/service@2021-12-01-preview' existing = {
  name: conventions.global.apiManagement[referential.environment].name
}

// === RESOURCES ===

@description('API Management backend')
resource backend 'Microsoft.ApiManagement/service/backends@2021-12-01-preview' = {
  name: backendName
  parent: apim
  properties: {
    protocol: 'http'
    url: backendUrl
    resourceId: resourceId
    credentials: credentials
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = backend.id

@description('The API Version of the deployed resource')
output apiVersion string = backend.apiVersion

@description('The Name of the deployed resource')
output name string = backend.name
