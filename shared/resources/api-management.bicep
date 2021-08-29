// Deploy an API Management
// Resources deployed from this template:
//   - API Management
// Required parameters:
//   - `organizationName`
//   - `applicationName`
//   - `environmentName`
//   - `hostName`
//   - `publisherEmail`
//   - `publisherName`
// Optional parameters:
//   [None]
// Outputs:
//   - `id`
//   - `apiVersion`
//   - `name`

// === PARAMETERS ===

@description('The organization name')
param organizationName string

@description('The application name')
param applicationName string

@description('The environment name of the deployment stage')
param environmentName string

@description('The host name of the deployment stage')
param hostName string


@description('The API publisher email')
@minLength(1)
param publisherEmail string

@description('The API publisher name')
@minLength(1)
param publisherName string

@description('The Application Insights ID')
param appInsightsId string

@description('The Application Insights instrumentation key')
param appInsightsInstrumentationKey string

// === VARIABLES ===

var location = resourceGroup().location
var apimName = '${organizationName}-${applicationName}-${hostName}-apim'

// === RESOURCES ===

// API Management
resource apim 'Microsoft.ApiManagement/service@2021-01-01-preview' = {
  name: apimName
  location: location
  sku: {
    name: 'Consumption'
    capacity: 0 // Needs to be at 0 for Consumption plan
  }
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    organization: organizationName
    application: applicationName
    environment: environmentName
    host: hostName
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    customProperties:{
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': 'true'
    }
  }

  resource logger 'loggers@2021-01-01-preview' = {
    name: 'logger-to-applicationInsights'
    properties: {
      loggerType: 'applicationInsights'
      resourceId: appInsightsId
      credentials: {
        'instrumentationKey': appInsightsInstrumentationKey
      }
    }
  }

  resource diagnostic 'diagnostics@2021-01-01-preview' = {
    name: 'diagnostic-from-applicationInsights'
    properties: {
      loggerId: logger.id
      alwaysLog: 'allErrors'
      sampling: {
        percentage: 100
        samplingType: 'fixed'
      }
    }
  }
}

// === OUTPUTS ===

output id string = apim.id
output apiVersion string = apim.apiVersion
output name string = apim.name
