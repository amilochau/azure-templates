/*
  Deploy a Key Vault
  Resources deployed from this template:
    - Key Vault
  Required parameters:
    - `referential`
  Optional parameters:
    [None]
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
    - `vaultUri`
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

// === VARIABLES ===

var location = resourceGroup().location
var tenantId = subscription().tenantId
var keyVaultName = '${referential.organization}-${referential.application}-${referential.host}-kv'

// === RESOURCES ===

// Key Vault
resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: keyVaultName
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

output id string = kv.id
output apiVersion string = kv.apiVersion
output name string = kv.name
output vaultUri string = kv.properties.vaultUri
