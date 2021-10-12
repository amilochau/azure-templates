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

var buildInRoles = json(loadTextContent('./build-in-roles.json'))

// === EXISTING ===

// Role
resource roleKeyVaultSecretsUser 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: buildInRoles['Key Vault Secrets User']
}

// Key Vault
resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}

// === AUTHORIZATIONS ===

// Principal to Key Vault
resource auth_app_kv 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(principalId, kv.id, roleKeyVaultSecretsUser.id)
  scope: kv
  properties: {
    roleDefinitionId: roleKeyVaultSecretsUser.id
    principalId: principalId
  }
}
