// Deploy a Key Vault
// Resources deployed from this template:
//   - Key Vault
// Required parameters:
//   [None]
// Optional parameters:
//   [None]
// Outputs:
//   - `id`
//   - `apiVersion`
//   - `name`
//   - `vaultUri`

// === VARIABLES ===

var location = resourceGroup().location
var tags = resourceGroup().tags
var tenantId = subscription().tenantId
var keyVaultName = '${tags.organization}-${tags.application}-${tags.host}-kv'

// === RESOURCES ===

// Key Vault
resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: keyVaultName
  location: location
  tags: resourceGroup().tags
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
