/*
  Deploy a delete lock for a Key Vault
*/

// === PARAMETERS ===

@description('Key Vault name')
param keyVaultName string

// === EXISTING ===

@description('Key Vault')
resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}

// === AUTHORIZATIONS ===

@description('Lock')
resource lock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: '${kv.name}-lock-delete'
  scope: kv
  properties: {
    level: 'CanNotDelete'
    notes: 'Key Vault vault should not be deleted, to avoid data loss.'
  }
}
