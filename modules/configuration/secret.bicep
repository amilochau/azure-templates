/*
  Deploy a Key Vault secret
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

@description('Key Vault')
resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}

// === RESOURCES ===

@description('Key Vault secret')
resource secret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: secretName
  parent: kv
  properties: {
    value: secretValue
  }
}

// === OUTPUTS ===

@description('The ID of the deployed Key Vault Secret')
output id string = secret.id

@description('The API Version of the deployed Key Vault Secret')
output apiVersion string = secret.apiVersion

@description('The Name of the deployed Key Vault Secret')
output name string = secret.name

@description('The URI of the deployed Key Vault Secret')
output secretUri string = secret.properties.secretUri
