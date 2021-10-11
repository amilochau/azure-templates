/*
  Deploy a list of Tags
  Resources deployed from this template:
    - Tags
  Required parameters:
    - `organizationName`
    - `applicationName`
    - `hostName`
  Optional parameters:
    [None]
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
    - `referential`
*/

// === PARAMETERS ===

@description('The organization name')
param organizationName string

@description('The application name')
param applicationName string

@description('The host name of the deployment stage')
param hostName string

@description('The current date')
param dateUtcNow string = utcNow('yyyy-MM-dd HH:mm:ss')

// === VARIABLES ===

var environmentName = startsWith(hostName, 'prd') ? 'Production' : startsWith(hostName, 'stg') ? 'Staging' : 'Development'

var referential = {
  organization: organizationName
  application: applicationName
  environment: environmentName
  host: hostName
  deploymentDate: dateUtcNow
}

// === RESOURCES ===

// Key Vault
resource tags 'Microsoft.Resources/tags@2021-04-01' = {
  name: 'default'
  properties: {
    tags: referential
  }
}

// === OUTPUTS ===

output id string = tags.id
output apiVersion string = tags.apiVersion
output name string = tags.name
output referential object = referential

output logAnalyticsWorkspaceName string = '${referential.organization}-monitoring-${referential.host}-ws'
output logAnalyticsWorkspaceResourceGroupName string = '${referential.organization}-monitoring-${referential.host}-rg'
output appConfigurationName string = '${referential.organization}-config-shd-cfg'
output appConfigurationResourceGroupName string = '${referential.organization}-config-shd-rg'
