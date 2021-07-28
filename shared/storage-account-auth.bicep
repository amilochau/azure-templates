// Deploy authorizations for a Storage Account
// Resources deployed from this template:
//   - Authorizations
// Required parameters:
//   - `principalId`
//   - `storageAccountName`
// Optional parameters:
//   - `readOnly`
// Optional parameters:
//   [None]
// Outputs:
//   [None]

// === PARAMETERS ===

@description('Principal ID')
param principalId string

@description('Storage Account name')
param storageAccountName string

@description('Assign a Read-Only authorization')
param readOnly bool = false

// === VARIABLES ===

var roleDefinitionIds = {
  // See https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
  // Or use command: az role definition list --name 'Storage Blob Data Contributor' --query [].name -o=tsv
  'Storage Blob Data Contributor': 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  'Storage Blob Data Reader': '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
}

// === RESOURCES ===

// Existing resources - Roles
resource roleStorageBlobDataContributor 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: roleDefinitionIds['Storage Blob Data Contributor']
}
resource roleStorageBlobDataReader 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: roleDefinitionIds['Storage Blob Data Reader']
}

// Existing resources - Key Vault
resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

// Authorizations - Application to Key Vault
resource auth_app_stg 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id, principalId, stg.id)
  scope: stg
  properties: {
    roleDefinitionId: readOnly ? roleStorageBlobDataReader.id : roleStorageBlobDataContributor.id
    principalId: principalId
  }
}
