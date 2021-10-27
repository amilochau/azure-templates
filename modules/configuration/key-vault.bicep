/*
  Deploy a Key Vault
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

// === VARIABLES ===

var location = resourceGroup().location
var tenantId = subscription().tenantId

// === RESOURCES ===

@description('Key Vault')
resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: conventions.naming.keyVault
  location: location
  tags: referential
  properties: {
    tenantId: tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    enableRbacAuthorization: true
  }
}

// === OUTPUTS ===

@description('The ID of the deployed Key Vault')
output id string = kv.id

@description('The API Version of the deployed Key Vault')
output apiVersion string = kv.apiVersion

@description('The Name of the deployed Key Vault')
output name string = kv.name

@description('The Vault URI of the deployed Key Vault')
output vaultUri string = kv.properties.vaultUri
