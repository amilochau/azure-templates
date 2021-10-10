/*
  Reference a Functions application as a dedicated backend into API Management
  Resources deployed from this template:
    - Functions key
    - API Management backend
  Required parameters:
    - `referential`
    - `apiManagementName`
    - `apiManagementResourceGroup`
    - `apiManagementKeyVaultName`
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

@description('The referential, from the tags.bicep module')
param referential object

@description('The API Management name')
param apiManagementName string

@description('The API Management resource group')
param apiManagementResourceGroup string

@description('The API Management key vaultname')
param apiManagementKeyVaultName string

@description('The Functions application name')
param functionsAppName string

// === VARIABLES ===

var apimFunctionsKeyName = '${referential.organization}-${referential.application}-${referential.host}-apim-functionskey'

// === EXISTING ===

// Functions application
resource fn 'Microsoft.Web/sites@2021-01-01' existing = {
  name: functionsAppName
}

// === RESOURCES ===

// Key Vault secret to store Functions key
module fn_key_kv './../key-vault/secret.bicep' = {
  name: 'Resource-FunctionsKeySecret'
  scope: resourceGroup(apiManagementResourceGroup)
  params: {
    keyVaultName: apiManagementKeyVaultName
    secretName: apimFunctionsKeyName
    secretValue: listkeys('${fn.id}/host/default', fn.apiVersion).functionKeys.default
  }
}

// Named value to store the Functions Key
module fn_key_apim '../api-management/named-value-secret.bicep' = {
  name: 'Resource-FunctionsKeyNamedValue'
  scope: resourceGroup(apiManagementResourceGroup)
  params: {
    apiManagementName: apiManagementName
    secretKey: apimFunctionsKeyName
    secretUri: fn_key_kv.outputs.secretUri
  }
}

// API Management backend
module apim_backend '../api-management/backend.bicep' = {
  name: 'Resource-FunctionsBackend'
  scope: resourceGroup(apiManagementResourceGroup)
  params: {
    backendUrl: 'https://${fn.properties.defaultHostName}/'
    apiManagementName: apiManagementName
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

output id string = apim_backend.outputs.id
output apiVersion string = apim_backend.outputs.apiVersion
output name string = apim_backend.outputs.name
output backendId string = apim_backend.outputs.backendId
