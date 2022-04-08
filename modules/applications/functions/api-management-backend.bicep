/*
  Reference a Functions application as a dedicated backend into API Management
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The Functions application name')
param functionsAppName string

@description('The relative URL of the Functions application host')
param relativeFunctionsUrl string

@description('The API version')
param apiVersion string

@description('Whether a subscription is required')
param subscriptionRequired bool

@description('The products to link with the API Management API')
param products array

@description('The OpenAPI link, relative to the application host name')
param relativeOpenApiUrl string

// === VARIABLES ===

var apimFunctionsKeyName = '${conventions.naming.prefix}${conventions.naming.suffixes.apiManagement}-functionskey'

// === EXISTING ===

@description('Functions application')
resource fn 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionsAppName
}

// === RESOURCES ===

@description('Key Vault secret to store Functions key')
module fn_key_kv '../../configuration/secret.bicep' = {
  name: 'Resource-FunctionsKeySecret'
  scope: resourceGroup(conventions.global.apiManagement[referential.environment].resourceGroupName)
  params: {
    keyVaultName: conventions.global.apiManagement[referential.environment].keyVaultName
    secretName: apimFunctionsKeyName
    secretValue: listkeys('${fn.id}/host/default', fn.apiVersion).functionKeys.default
  }
}

@description('Named value to store the Functions Key')
module fn_key_apim '../../api-management/named-value-secret.bicep' = {
  name: 'Resource-FunctionsKeyNamedValue'
  scope: resourceGroup(conventions.global.apiManagement[referential.environment].resourceGroupName)
  params: {
    referential: referential
    conventions: conventions
    secretKey: apimFunctionsKeyName
    secretUri: fn_key_kv.outputs.secretUri
  }
}

@description('API Management backend')
module apimBackend '../../api-management/backend.bicep' = {
  name: 'Resource-FunctionsBackend'
  scope: resourceGroup(conventions.global.apiManagement[referential.environment].resourceGroupName)
  params: {
    backendUrl: 'https://${fn.properties.defaultHostName}${relativeFunctionsUrl}/'
    referential: referential
    conventions: conventions
    resourceId: '${environment().resourceManager}${fn.id}'
    backendName: functionsAppName
    credentials: {
      header: {
        'x-functions-key': [
            '{{${fn_key_apim.outputs.name}}}'
        ]
      }
    }
  }
}

@description('API Management API registration with OpenAPI')
module apimApi '../../api-management/api-openapi.bicep' = {
  name: 'Resource-ApiManagementApi'
  scope: resourceGroup(conventions.global.apiManagement[referential.environment].resourceGroupName)
  params: {
    applicationName: referential.application
    referential: referential
    conventions: conventions
    backendId: apimBackend.outputs.name
    apiVersion: apiVersion
    subscriptionRequired: subscriptionRequired
    products: products
    openApiLink: 'https://${fn.properties.defaultHostName}${relativeOpenApiUrl}'
  }
}

// === OUTPUTS ===

@description('The ID of the deployed API Management Backend')
output id string = apimBackend.outputs.id

@description('The API Version of the deployed API Management Backend')
output apiVersion string = apimBackend.outputs.apiVersion

@description('The Name of the deployed API Management Backend')
output name string = apimBackend.outputs.name
