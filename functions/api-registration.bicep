/*
  Deploy infrastructure for Azure Functions API registration
  Resources deployed from this template:
    - API Management registrations
  Required parameters:
    - `organizationName`
    - `applicationName`
    - `hostName`
  Optional parameters:
    - `apiManagementProducts`
    - `apiManagementSubscriptionRequired`
    - `apiManagementVersion`
    - `relativeOpenApiUrl`
    - `relativeFunctionsUrl`
  Outputs:
    [None]
*/

// === PARAMETERS ===

@description('The organization name')
@minLength(3)
@maxLength(3)
param organizationName string

@description('The application name')
@minLength(3)
@maxLength(12)
param applicationName string

@description('The host name of the deployment stage')
@minLength(3)
@maxLength(5)
param hostName string


@description('The products to link with the API Management API')
param apiManagementProducts array = []

@description('Whether an API Management subscription is required')
param apiManagementSubscriptionRequired bool = true

@description('The API Management API version')
param apiManagementVersion string = 'v1'

@description('The OpenAPI link, relative to the application host name')
param relativeOpenApiUrl string = '/api/swagger.json'

@description('The relative URL of the Functions application host')
param relativeFunctionsUrl string = '/api'

// === VARIABLES ===

var conventions = json(replace(replace(replace(loadTextContent('../modules/global/conventions.json'), '%ORGANIZATION%', organizationName), '%APPLICATION%', applicationName), '%HOST%', hostName))

// === EXISTING ===

// Functions application
resource fn 'Microsoft.Web/sites@2021-01-15' existing = {
  name: conventions.naming.functionsApplication.name
}

// === RESOURCES ===

// API Management backend
module apimBackend '../modules/functions/api-management-backend.bicep' = if (!empty(apiManagementProducts)) {
  name: 'Resource-ApiManagementBackend'
  params: {
    conventions: conventions
    functionsAppName: fn.name
    relativeFunctionsUrl: relativeFunctionsUrl
  }
}

// API Management API registration with OpenAPI
module apimApi '../modules/api-management/api-openapi.bicep' = if (!empty(apiManagementProducts)) {
  name: 'Resource-ApiManagementApi'
  scope: resourceGroup(conventions.global.apiManagementResourceGroupName)
  params: {
    applicationName: applicationName
    conventions: conventions
    backendId: !empty(apiManagementProducts) ? apimBackend.outputs.backendId : ''
    apiVersion: apiManagementVersion
    subscriptionRequired: apiManagementSubscriptionRequired
    products: apiManagementProducts
    openApiLink: 'https://${fn.properties.defaultHostName}${relativeOpenApiUrl}'
  }
}
