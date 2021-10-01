/*
  Deploy an API Management backend
  Resources deployed from this template:
    - API Management backend
  Required parameters:
    - `apiManagementName`
    - `backendId`
    - `backendName`
    - `backendUrl`
  Optional parameters:
    - `credentials`
  Outputs:
    [None]
*/

// === PARAMETERS ===

@description('The API Management name')
param apiManagementName string

@description('The backend ID')
param backendId string

@description('The backend name')
param backendName string

@description('The backend URL')
param backendUrl string

@description('The backend credentials')
param credentials object = {}

// === EXISTING ===

// API Management
resource apim 'Microsoft.ApiManagement/service@2021-01-01-preview' existing = {
  name: apiManagementName
}

// === RESOURCES ===

// API Management backend
resource apim_backend 'Microsoft.ApiManagement/service/backends@2021-01-01-preview' = {
  name: backendName
  parent: apim
  properties: {
    protocol: 'http'
    url: backendUrl
    resourceId: backendId
    credentials: credentials
  }
}
