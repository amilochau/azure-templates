/*
  Deploy a Key Vault
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The deployment location')
param location string

// === VARIABLES ===

var tenantId = subscription().tenantId
var keyVaultName = '${conventions.naming.prefix}${conventions.naming.suffixes.keyVault}'

// === RESOURCES ===

@description('Key Vault')
resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: replace(keyVaultName, '-', '')
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
    enableRbacAuthorization: true // true = Enforcing AAD as the only authentication method
  }
}

@description('Lock')
module lock '../authorizations/locks/key-vault-delete.bicep' = {
  name: 'Resource-Lock-Delete'
  params: {
    keyVaultName: kv.name
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = kv.id

@description('The API Version of the deployed resource')
output apiVersion string = kv.apiVersion

@description('The Name of the deployed resource')
output name string = kv.name

@description('The Vault URI of the deployed resource')
output vaultUri string = kv.properties.vaultUri
