/*
  Deploy authorizations for a Key Vault
  Resources deployed from this template:
    - Authorizations
  Required parameters:
    - `principalId`
    - `keyVaultName`
  Optional parameters:
    [None]
  Outputs:
    [None]
*/

// === PARAMETERS ===

@description('Principal ID')
param principalId string

@description('Key Vault name')
param keyVaultName string

// === VARIABLES ===

var roleDefinitionIds = {
  'Key Vault Secrets User': '4633458b-17de-408a-b874-0445c86b69e6'
}

// === EXISTING ===

// Role
resource roleKeyVaultSecretsUser 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: roleDefinitionIds['Key Vault Secrets User']
}

// Key Vault
resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}

// === AUTHORIZATIONS ===

// Principal to Key Vault
resource auth_app_kv 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id, principalId, kv.id)
  scope: kv
  properties: {
    roleDefinitionId: roleKeyVaultSecretsUser.id
    principalId: principalId
  }
}
