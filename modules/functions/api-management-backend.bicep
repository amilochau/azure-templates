/*
  Reference a Functions application as a dedicated backend into API Management
*/

// === PARAMETERS ===

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The Functions application name')
param functionsAppName string

@description('The relative URL of the Functions application host')
param relativeFunctionsUrl string

// === VARIABLES ===

var apimFunctionsKeyName = '${conventions.naming.apiManagement}-functionskey'

// === EXISTING ===

@description('Functions application')
resource fn 'Microsoft.Web/sites@2021-01-01' existing = {
  name: functionsAppName
}

// === RESOURCES ===

@description('Key Vault secret to store Functions key')
module fn_key_kv '../configuration/secret.bicep' = {
  name: 'Resource-FunctionsKeySecret'
  scope: resourceGroup(conventions.global.apiManagement.resourceGroupName)
  params: {
    keyVaultName: conventions.global.apiManagement.keyVaultName
    secretName: apimFunctionsKeyName
    secretValue: listkeys('${fn.id}/host/default', fn.apiVersion).functionKeys.default
  }
}

@description('Named value to store the Functions Key')
module fn_key_apim '../api-management/named-value-secret.bicep' = {
  name: 'Resource-FunctionsKeyNamedValue'
  scope: resourceGroup(conventions.global.apiManagement.resourceGroupName)
  params: {
    conventions: conventions
    secretKey: apimFunctionsKeyName
    secretUri: fn_key_kv.outputs.secretUri
  }
}

@description('API Management backend')
module apimBackend '../api-management/backend.bicep' = {
  name: 'Resource-FunctionsBackend'
  scope: resourceGroup(conventions.global.apiManagement.resourceGroupName)
  params: {
    backendUrl: 'https://${fn.properties.defaultHostName}${relativeFunctionsUrl}/'
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

// === OUTPUTS ===

@description('The ID of the deployed API Management Backend')
output id string = apimBackend.outputs.id

@description('The API Version of the deployed API Management Backend')
output apiVersion string = apimBackend.outputs.apiVersion

@description('The Name of the deployed API Management Backend')
output name string = apimBackend.outputs.name
