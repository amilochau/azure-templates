/*
  Deploy infrastructure for Azure App Configuration
  Resources deployed from this template:
    - App Configuration
  Required parameters:
    - `organizationName`
    - `applicationName`
    - `hostName`
  Outputs:
    [None]
*/

// === PARAMETERS ===

@description('The organization name')
@minLength(3)
@maxLength(3)
param organizationName string

@description('The application name')
@minLength(3)
@maxLength(12)
param applicationName string

@description('The host name of the deployment stage')
@minLength(3)
@maxLength(5)
param hostName string

// === RESOURCES ===

// Tags
module tags '../modules/resources/tags.bicep' = {
  name: 'Resource-Tags'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    hostName: hostName
  }
}

module appConfig '../modules/resources/app-config.bicep' = {
  name: 'Resource-AppConfiguration'
  params: {
    referential: {
      referential: tags.outputs.referential
    }
  }
}
