/*
  Deploy an API Management backend
  Resources deployed from this template:
    - API Management backend
  Required parameters:
    - `conventions`
    - `resourceId`
    - `backendName`
    - `backendUrl`
  Optional parameters:
    - `credentials`
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
    - `backendId`
*/

// === PARAMETERS ===

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

// API Management
resource apim 'Microsoft.ApiManagement/service@2021-01-01-preview' existing = {
  name: conventions.global.apiManagementName
}

// === RESOURCES ===

// API Management backend
resource backend 'Microsoft.ApiManagement/service/backends@2021-01-01-preview' = {
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

output id string = backend.id
output apiVersion string = backend.apiVersion
output name string = backend.name
output backendId string = backend.name
