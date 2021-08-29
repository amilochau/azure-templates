// Deploy infrastructure for Azure App Configuration
// Resources deployed from this template:
//   - App Configuration
// Required parameters:
//   - `organizationName`
//   - `applicationName`
//   - `environmentName`
//   - `hostName`
// Outputs:
//   [None]

// === PARAMETERS ===

@description('The organization name')
param organizationName string

@description('The application name')
param applicationName string

@description('The environment name of the deployment stage')
param environmentName string

@description('The host name of the deployment stage')
param hostName string

// === RESOURCES ===

// Tags
module tags '../shared/resources/tags.bicep' = {
  name: 'Resource-Tags'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    environmentName: environmentName
    hostName: hostName
  }
}

module appConfig '../shared/resources/app-config.bicep' = {
  name: 'Resource-AppConfiguration'
  params: {
    referential: {
      referential: tags.outputs.referential
    }
  }
}
