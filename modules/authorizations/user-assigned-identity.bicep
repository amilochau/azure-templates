/*
  Deploy a User-Assigned Identity for the current application itself
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The type of UAI to deploy')
@allowed([
  'application'
  'clients'
])
param type string

@description('The deployment location')
param location string

// === VARIABLES ===

var uaiNameSuffix = type == 'application' ? conventions.naming.suffixes.userAssignedIdentityApplication : conventions.naming.suffixes.userAssignedIdentityClients

// === RESOURCES ===

@description('User assigned Managed identity')
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${conventions.naming.prefix}${uaiNameSuffix}'
  location: location
  tags: referential
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = userAssignedIdentity.id

@description('The API Version of the deployed resource')
output apiVersion string = userAssignedIdentity.apiVersion

@description('The Name of the deployed resource')
output name string = userAssignedIdentity.name

@description('The Principal ID of the deployed resource')
output principalId string = userAssignedIdentity.properties.principalId

@description('The Client ID of the deployed resource')
output clientId string = userAssignedIdentity.properties.clientId
