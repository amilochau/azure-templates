/*
  Deploy a Key Vault secret
  Resources deployed from this template:
    - Key Vault
  Required parameters:
    - `keyVaultName`
    - `secretName`
    - `secretValue`
  Optional parameters:
    [None]
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
    - `secretUri`
*/

// === PARAMETERS ===

@description('The Key Vault name')
param keyVaultName string

@description('The secret name')
param secretName string

@description('The secret value')
@secure()
param secretValue string

// === EXISTING ===

// Key Vault
resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}

// === RESOURCES ===

resource kv_secret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: secretName
  parent: kv
  properties: {
    value: secretValue
  }
}

// === OUTPUTS ===

output id string = kv_secret.id
output apiVersion string = kv_secret.apiVersion
output name string = kv_secret.name
output secretUri string = kv_secret.properties.secretUri
