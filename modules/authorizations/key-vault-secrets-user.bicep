/*
  Deploy authorizations for a Key Vault
*/

// === PARAMETERS ===

@description('Principal ID')
param principalId string

@description('Key Vault name')
param keyVaultName string

@description('The role description')
param roleDescription string

// === VARIABLES ===

var buildInRoles = json(loadTextContent('./built-in-roles.json'))

// === EXISTING ===

@description('Role - Key Vault Secrets User')
resource roleKeyVaultSecretsUser 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: buildInRoles['Key Vault Secrets User']
}

@description('Key Vault')
resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}

// === AUTHORIZATIONS ===

@description('Principal to Key Vault')
resource auth_app_kv 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(principalId, kv.id, roleKeyVaultSecretsUser.id)
  scope: kv
  properties: {
    roleDefinitionId: roleKeyVaultSecretsUser.id
    principalId: principalId
    description: roleDescription
    principalType: 'ServicePrincipal'
  }
}
