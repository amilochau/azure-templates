// Deploy a Key Vault
// Resources deployed from this template:
//   - Key Vault
// Optional parameters:
//   - `keyVaultName`
// Outputs:
//   - `id`
//   - `apiVersion`
//   - `name`
//   - `vaultUri`

// === PARAMETERS ===

@description('Key Vault name')
param keyVaultName string

// === VARIABLES ===

var location = resourceGroup().location
var tenantId = subscription().tenantId

// === RESOURCES ===

// Key Vault
resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: true
  }
}

// === OUTPUTS ===

output id string = kv.id
output apiVersion string = kv.apiVersion
output name string = kv.name
output vaultUri string = kv.properties.vaultUri
