/*
  Deploy authorizations for a shared Azure App Configuration
  Resources deployed from this template:
    - Authorizations
  Required parameters:
    - `principalId`
    - `appConfigurationName`
    - `roleDescription`
  Optional parameters:
    [None]
  Outputs:
    [None]
*/

// === PARAMETERS ===

@description('Principal ID')
param principalId string

@description('App Configuration name')
param appConfigurationName string

@description('The role description')
param roleDescription string

// === VARIABLES ===

var buildInRoles = json(loadTextContent('./build-in-roles.json'))

// === EXISTING ===

@description('Role - App Configuration Data Reader')
resource roleAppConfigurationDataReader 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: buildInRoles['App Configuration Data Reader']
}

@description('App Configuration')
resource appConfig 'Microsoft.AppConfiguration/configurationStores@2021-03-01-preview' existing = {
  name: appConfigurationName
}

// === AUTHORIZATIONS ===

@description('Principal to App Configuration')
resource auth_app_appConfig 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(principalId, appConfig.id, roleAppConfigurationDataReader.id)
  scope: appConfig
  properties: {
    roleDefinitionId: roleAppConfigurationDataReader.id
    principalId: principalId
    description: roleDescription
  }
}
