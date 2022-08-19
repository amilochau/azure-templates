/*
  Deploy an API Management named value
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The secret name')
param secretName string

@description('The secret URI')
param secretUri string

// === EXISTING ===

@description('API Management')
resource apim 'Microsoft.ApiManagement/service@2021-12-01-preview' existing = {
  name: conventions.global.apiManagement[referential.environment].name
}

// === RESOURCES ===

@description('API Management Named value')
resource namedValue 'Microsoft.ApiManagement/service/namedValues@2021-12-01-preview' = {
  name: secretName
  parent: apim
  properties: {
    displayName: secretName
    keyVault: {
      secretIdentifier: secretUri
    }
    secret: true
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = namedValue.id

@description('The API Version of the deployed resource')
output apiVersion string = namedValue.apiVersion

@description('The Name of the deployed resource')
output name string = namedValue.name
