/*
  Deploy an API Management named value
  Resources deployed from this template:
    - API Management named value
  Required parameters:
    - `conventions`
    - `secretKey`
    - `secretUri`
  Optional parameters:
    [None]
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
*/

// === PARAMETERS ===

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The secret key')
param secretKey string

@description('The secret URI')
param secretUri string

// === EXISTING ===

// API Management
resource apim 'Microsoft.ApiManagement/service@2021-01-01-preview' existing = {
  name: conventions.global.apiManagementName
}

// === RESOURCES ===

// API Management Named value
resource namedValue 'Microsoft.ApiManagement/service/namedValues@2021-01-01-preview' = {
  name: secretKey
  parent: apim
  properties: {
    displayName: secretKey
    keyVault: {
      secretIdentifier: secretUri
    }
    secret: true
  }
}

// === OUTPUTS ===

output id string = namedValue.id
output apiVersion string = namedValue.apiVersion
output name string = namedValue.name
