/*
  Deploy a list of tags to the current resource group
*/

// === PARAMETERS ===

@description('The organization name')
param organizationName string

@description('The application name')
param applicationName string

@description('The host name of the deployment stage')
param hostName string

@description('The region name')
param regionName string

@description('The azure-templates version')
param templateVersion string

@description('The current date - do not override the default value')
param dateUtcNow string = utcNow('yyyy-MM-dd HH:mm:ss')

@description('Whether referential should not be added as resource group tags')
param disableResourceGroupTags bool = false

// === VARIABLES ===

var environmentName = startsWith(hostName, 'prd') ? 'Production' : startsWith(hostName, 'stg') ? 'Staging' : 'Development'

var referential = {
  organization: organizationName
  application: applicationName
  environment: environmentName
  host: hostName
  regionName: regionName
  templateVersion: templateVersion
  deploymentDate: dateUtcNow
}

// === RESOURCES ===

@description('Resource group tags')
resource tags 'Microsoft.Resources/tags@2021-04-01' = if(!disableResourceGroupTags) {
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
output environmentName string = environmentName
