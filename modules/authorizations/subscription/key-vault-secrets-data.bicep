/*
  Deploy authorizations for a Key Vault
*/

// === PARAMETERS ===

@description('Principal ID')
param principalId string

@description('Principal Type')
@allowed([
  'ServicePrincipal'
  'Group'
])
param principalType string = 'ServicePrincipal'

@description('Key Vault name')
param keyVaultName string

@description('The role type')
@allowed([
  'Admin'
  'Reader' // Recommended for most use cases
])
param roleType string

@description('The role description')
param roleDescription string

// === VARIABLES ===

var buildInRoles = json(loadTextContent('../../global/built-in-roles.json'))
var roleName = roleType == 'Admin' ? buildInRoles['Key Vault Secrets Officer'] : buildInRoles['Key Vault Secrets User']

// === EXISTING ===

@description('Role')
resource role 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: roleName
}

@description('Key Vault')
resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}

// === AUTHORIZATIONS ===

@description('Principal to Key Vault')
resource auth_app_kv 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(principalId, kv.id, role.id)
  scope: kv
  properties: {
    roleDefinitionId: role.id
    principalId: principalId
    description: roleDescription
    principalType: principalType
  }
}
