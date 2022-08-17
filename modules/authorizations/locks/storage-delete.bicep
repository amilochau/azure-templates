/*
  Deploy a delete lock for a Storage account
*/

// === PARAMETERS ===

@description('Storage Account name')
param storageAccountName string

// === EXISTING ===

@description('Storage account')
resource stg 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}

// === AUTHORIZATIONS ===

@description('Lock')
resource lock 'Microsoft.Authorization/locks@2017-04-01' = { // @2020-05-01 is not available in westeurope
  name: '${stg.name}-lock-delete'
  scope: stg
  properties: {
    level: 'CanNotDelete'
    notes: 'Storage accounts and containers should not be deleted, to avoid data loss.'
  }
}
