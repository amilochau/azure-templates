/*
  Deploy an Availability Test for UI application
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The ID of the Application Insights to link')
param applicationInsightsId string

@description('The host name of the application to test')
param applicationHostName string

@description('The deployment location')
param location string

// === VARIABLES ===

@description('Web tests settings')
var webTestsSettings = loadJsonContent('../../global/web-tests-settings.json', 'ui')

// === RESOURCES ===

@description('Web tests on Functions application')
module webTest_functions './web-test-ping.bicep' = {
  name: 'Resource-WebTests-UI'
  params: {
    referential: referential
    conventions: conventions
    location: location
    targetUrl: 'https://${applicationHostName}${webTestsSettings.urlSuffix}'
    applicationInsightsId: applicationInsightsId
    comment: 'UI availability tests'
    suffix: 'ui'
    testLocations: webTestsSettings.locations
  }
}
