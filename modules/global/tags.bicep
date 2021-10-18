/*
  Deploy a list of Tags
  Resources deployed from this template:
    - Tags
  Required parameters:
    - `organizationName`
    - `applicationName`
    - `hostName`
    - `templateVersion`
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

@description('The azure-templates version')
param templateVersion string

@description('The current date')
param dateUtcNow string = utcNow('yyyy-MM-dd HH:mm:ss')

// === VARIABLES ===

var environmentName = startsWith(hostName, 'prd') ? 'Production' : startsWith(hostName, 'stg') ? 'Staging' : 'Development'

var referential = {
  organization: organizationName
  application: applicationName
  environment: environmentName
  host: hostName
  templateVersion: templateVersion
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
