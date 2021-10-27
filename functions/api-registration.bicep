/*
  REgister an Azure Functions into API Management
*/

// === PARAMETERS ===

@description('The organization name')
@minLength(3)
@maxLength(3)
param organizationName string

@description('The application name')
@minLength(3)
@maxLength(11)
param applicationName string

@description('The host name of the deployment stage')
@minLength(3)
@maxLength(5)
param hostName string

@description('The ARM templates version')
@minLength(1)
param templateVersion string


@description('The products to link with the API Management API')
param apiManagementProducts array = []

@description('Whether an API Management subscription is required')
param apiManagementSubscriptionRequired bool = true

@description('The API Management API version')
@minLength(1)
param apiManagementVersion string = 'v1'

@description('The OpenAPI link, relative to the application host name')
@minLength(1)
param relativeOpenApiUrl string = '/api/swagger.json'

@description('The relative URL of the Functions application host')
@minLength(1)
param relativeFunctionsUrl string = '/api'

// === VARIABLES ===

@description('The region name')
var regionName = json(loadTextContent('../modules/global/regions.json'))[resourceGroup().location]

@description('Global & naming conventions')
var conventions = json(replace(replace(replace(replace(loadTextContent('../modules/global/conventions.json'), '%ORGANIZATION%', organizationName), '%APPLICATION%', applicationName), '%HOST%', hostName), '%REGION%', regionName))

// === EXISTING ===

@description('Functions application')
resource fn 'Microsoft.Web/sites@2021-01-15' existing = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.functionsApplication}'
}

// === RESOURCES ===

@description('Resource groupe tags')
module tags '../modules/global/tags.bicep' = {
  name: 'Resource-Tags'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    hostName: hostName
    regionName: regionName
    templateVersion: templateVersion
    disableResourceGroupTags: true
  }
}

@description('API Management backend')
module apimBackend '../modules/functions/api-management-backend.bicep' = if (!empty(apiManagementProducts)) {
  name: 'Resource-ApiManagementBackend'
  params: {
    conventions: conventions
    functionsAppName: fn.name
    relativeFunctionsUrl: relativeFunctionsUrl
  }
}

@description('API Management API registration with OpenAPI')
module apimApi '../modules/api-management/api-openapi.bicep' = if (!empty(apiManagementProducts)) {
  name: 'Resource-ApiManagementApi'
  scope: resourceGroup(conventions.global.apiManagement.resourceGroupName)
  params: {
    applicationName: applicationName
    conventions: conventions
    backendId: !empty(apiManagementProducts) ? apimBackend.outputs.name : ''
    apiVersion: apiManagementVersion
    subscriptionRequired: apiManagementSubscriptionRequired
    products: apiManagementProducts
    openApiLink: 'https://${fn.properties.defaultHostName}${relativeOpenApiUrl}'
  }
}
