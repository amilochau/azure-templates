/*
  Deploy an Application Insights Ping Web Test
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The ID of the Application Insights to link')
param applicationInsightsId string

@description('The target URL to test')
param targetUrl string

@description('The test locations')
param testLocations array

@description('The web test comment')
param comment string

@description('The web test suffix')
param suffix string

@description('The test frequency in seconds')
@allowed([
  300
  600
  900
])
param frequency int = 900

@description('The test timeout in seconds')
param timeout int = 60

@description('The deployment location')
param location string

// === VARIABLES ===

var webTestName = '${conventions.naming.prefix}${conventions.naming.suffixes.webTest}-${suffix}'
var specificTags = {
  comment: comment
  'hidden-link:${applicationInsightsId}': 'Resource'
}
var webTestConfiguration = replace(replace(replace(loadTextContent('../../global/web-test-ping-template.xml'), '%TEST_NAME%', webTestName), '%TEST_URL%', targetUrl), '%TEST_DESCRIPTION%', comment)
var tags = union(referential, specificTags)

// === RESOURCES ===

@description('Ping test')
resource webTest 'Microsoft.Insights/webtests@2018-05-01-preview' = { // @2020-10-05-preview is not available in westeurope
  name: webTestName
  location: location
  tags: tags
  kind: 'ping'
  properties: {
    Name: targetUrl
    Description: comment
    Enabled: true
    Frequency: frequency
    Timeout: timeout
    SyntheticMonitorId: targetUrl
    Kind: 'ping'
    RetryEnabled: true
    Locations: [ for testLocation in testLocations: {
      Id: testLocation
    }]
    Configuration: {
      WebTest: webTestConfiguration
    }
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = webTest.id

@description('The API Version of the deployed resource')
output apiVersion string = webTest.apiVersion

@description('The Name of the deployed resource')
output name string = webTest.name
