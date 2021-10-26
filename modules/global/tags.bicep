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

var environmentName = startsWith(hostName, 'shd') ? 'Shared' : startsWith(hostName, 'prd') ? 'Production' : startsWith(hostName, 'stg') ? 'Staging' : 'Development'

var referential = {
  organization: organizationName
  application: applicationName
  environment: environmentName
  host: hostName
  region: regionName
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

@description('The ID of the deployed API Management')
output id string = tags.id

@description('The API Version of the deployed API Management')
output apiVersion string = tags.apiVersion

@description('The Name of the deployed API Management')
output name string = tags.name

@description('The resource group referential; the following properties are exposed: `organization`, `application`, `environemnt`, `host`, `region`, `templateVersion`, `deploymentDate`')
output referential object = referential
