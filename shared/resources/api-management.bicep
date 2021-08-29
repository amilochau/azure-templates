// Deploy an API Management
// Resources deployed from this template:
//   - API Management
// Required parameters:
//   - `publisherEmail`
//   - `publisherName`
// Optional parameters:
//   [None]
// Outputs:
//   - `id`
//   - `apiVersion`
//   - `name`

// === PARAMETERS ===

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
var tags = resourceGroup().tags
var apimName = '${tags.organization}-${tags.application}-${tags.host}-apim'

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
  tags: tags
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    customProperties:{
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': 'true'
    }
  }

  resource logger 'loggers@2021-01-01-preview' = {
    name: 'logger-applicationinsights'
    properties: {
      loggerType: 'applicationInsights'
      resourceId: appInsightsId
      credentials: {
        'instrumentationKey': appInsightsInstrumentationKey
      }
    }
  }

  resource diagnostic 'diagnostics@2021-01-01-preview' = {
    name: 'applicationinsights'
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
