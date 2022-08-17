/*
  Deploy a delete lock for an App Configuration
*/

// === PARAMETERS ===

@description('App Configuration name')
param appConfigurationName string

// === EXISTING ===

@description('App Configuration')
resource appConfig 'Microsoft.AppConfiguration/configurationStores@2021-03-01-preview' existing = {
  name: appConfigurationName
}

// === AUTHORIZATIONS ===

@description('Lock')
resource lock 'Microsoft.Authorization/locks@2017-04-01' = { // @2020-05-01 is not available in westeurope
  name: '${appConfig.name}-lock-delete'
  scope: appConfig
  properties: {
    level: 'CanNotDelete'
    notes: 'App Configuration stores should not be deleted, to avoid data loss.'
  }
}
