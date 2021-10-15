/*
  Reference a Functions application as a dedicated backend into API Management
  Resources deployed from this template:
    - API Management backend
  Required parameters:
    - `conventions`
    - `functionsAppName`
  Optional parameters:
    [None]
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
    - `backendId`
*/

// === PARAMETERS ===

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The Functions application name')
param functionsAppName string

// === VARIABLES ===

var apimFunctionsKeyName = '${conventions.naming.apiManagement.name}-functionskey'

// === EXISTING ===

// Functions application
resource fn 'Microsoft.Web/sites@2021-01-01' existing = {
  name: functionsAppName
}

// === RESOURCES ===

// Key Vault secret to store Functions key
module fn_key_kv '../configuration/secret.bicep' = {
  name: 'Resource-FunctionsKeySecret'
  scope: resourceGroup(conventions.global.apiManagementResourceGroupName)
  params: {
    keyVaultName: conventions.global.apiManagementKeyVaultName
    secretName: apimFunctionsKeyName
    secretValue: listkeys('${fn.id}/host/default', fn.apiVersion).functionKeys.default
  }
}

// Named value to store the Functions Key
module fn_key_apim '../api-management/named-value-secret.bicep' = {
  name: 'Resource-FunctionsKeyNamedValue'
  scope: resourceGroup(conventions.global.apiManagementResourceGroupName)
  params: {
    conventions: conventions
    secretKey: apimFunctionsKeyName
    secretUri: fn_key_kv.outputs.secretUri
  }
}

// API Management backend
module apimBackend '../api-management/backend.bicep' = {
  name: 'Resource-FunctionsBackend'
  scope: resourceGroup(conventions.global.apiManagementResourceGroupName)
  params: {
    backendUrl: 'https://${fn.properties.defaultHostName}/'
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

output id string = apimBackend.outputs.id
output apiVersion string = apimBackend.outputs.apiVersion
output name string = apimBackend.outputs.name
output backendId string = apimBackend.outputs.backendId
