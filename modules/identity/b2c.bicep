/*
  Deploy an AAD B2C directory
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The deployment location')
param location string

@description('The name of the tenant')
param tenantName string

// === VARIABLES ===

var b2cDirectoryName = '${tenantName}.onmicrosoft.com'

// === RESOURCES ===

@description('The AAD B2C directory')
resource b2cDirectory 'Microsoft.AzureActiveDirectory/b2cDirectories@2021-04-01' = {
  name: b2cDirectoryName
  location: location
  tags: referential
  sku: {
    tier: 'A0'
    name: 'PremiumP1'
  }
  properties: {
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = b2cDirectory.id

@description('The API Version of the deployed resource')
output apiVersion string = b2cDirectory.apiVersion

@description('The Name of the deployed resource')
output name string = b2cDirectory.name
