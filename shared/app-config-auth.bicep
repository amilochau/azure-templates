// Deploy authorizations for a shared Azure App Configuration
// Resources deployed from this template:
//   - Authorizations
// Optional parameters:
//   - `principalId`
//   - `appConfigurationName`
// Outputs:
//   [None]

// === PARAMETERS ===

@description('Principal ID')
param principalId string

@description('App Configuration name')
param appConfigurationName string

// === VARIABLES ===

var roleDefinitionIds = {
  // See https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
  // Or use command: az role definition list --name 'Key Vault Secrets Officer' --query [].name -o=tsv
  'App Configuration Data Reader': '516239f1-63e1-4d78-a4de-a74fb236a071'
}

// === RESOURCES ===

// Existing resources - Role
resource roleAppConfigurationDataReader 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: roleDefinitionIds['App Configuration Data Reader']
}

// Existing resources - App Configuration
resource appConfig 'Microsoft.AppConfiguration/configurationStores@2021-03-01-preview' existing = {
  name: appConfigurationName
}

// Authorizations - Application to App Configuration
resource auth_app_appConfig 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id, principalId, appConfig.id)
  scope: appConfig
  properties: {
    roleDefinitionId: roleAppConfigurationDataReader.id
    principalId: principalId
  }
}
