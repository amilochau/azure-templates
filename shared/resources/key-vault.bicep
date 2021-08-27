// Deploy a Key Vault
// Resources deployed from this template:
//   - Key Vault
// Required parameters:
//   - `organizationName`
//   - `applicationName`
//   - `environmentName`
//   - `hostName`
// Optional parameters:
//   [None]
// Outputs:
//   - `id`
//   - `apiVersion`
//   - `name`
//   - `vaultUri`

// === PARAMETERS ===

@description('The organization name')
param organizationName string

@description('The application name')
param applicationName string

@description('The environment name of the deployment stage')
param environmentName string

@description('The host name of the deployment stage')
param hostName string

// === VARIABLES ===

var location = resourceGroup().location
var tenantId = subscription().tenantId
var keyVaultName = '${organizationName}-${applicationName}-${hostName}-kv'

// === RESOURCES ===

// Key Vault
resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: keyVaultName
  location: location
  tags:{
    organization: organizationName
    application: applicationName
    environment: environmentName
    host: hostName
  }
  properties: {
    tenantId: tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    enableRbacAuthorization: true
  }
}

// === OUTPUTS ===

output id string = kv.id
output apiVersion string = kv.apiVersion
output name string = kv.name
output vaultUri string = kv.properties.vaultUri
