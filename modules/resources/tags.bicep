/*
  Deploy a list of Tags
  Resources deployed from this template:
    - Tags
  Required parameters:
    - `organizationName`
    - `applicationName`
    - `environmentName`
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

@description('The environment name of the deployment stage')
param environmentName string

@description('The host name of the deployment stage')
param hostName string

// === VARIABLES ===

var referential = {
  organization: organizationName
  application: applicationName
  environment: environmentName
  host: hostName
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
