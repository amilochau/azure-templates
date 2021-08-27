// Deploy authorizations for a shared Azure App Configuration
// Resources deployed from this template:
//   - Authorizations
// Required parameters:
//   - `principalId`
//   - `appConfigurationName`
// Optional parameters:
//   [None]
// Outputs:
//   [None]

// === PARAMETERS ===

@description('Principal ID')
param principalId string

@description('App Configuration name')
param appConfigurationName string

// === VARIABLES ===

var roleDefinitionIds = {
  'App Configuration Data Reader': '516239f1-63e1-4d78-a4de-a74fb236a071'
}

// === EXISTING ===

// Role
resource roleAppConfigurationDataReader 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: roleDefinitionIds['App Configuration Data Reader']
}

// App Configuration
resource appConfig 'Microsoft.AppConfiguration/configurationStores@2021-03-01-preview' existing = {
  name: appConfigurationName
}

// === AUTHORIZATIONS ===

// Principal to App Configuration
resource auth_app_appConfig 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id, principalId, appConfig.id)
  scope: appConfig
  properties: {
    roleDefinitionId: roleAppConfigurationDataReader.id
    principalId: principalId
  }
}
