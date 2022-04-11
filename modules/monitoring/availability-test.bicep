/*
  Deploy an Application Insights Standard Availability Test
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

@description('The availability test comment')
param comment string

@description('The availability test suffix')
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

var availabilityTestName = '${conventions.naming.prefix}${conventions.naming.suffixes.webTest}-${suffix}'
var specificTags = {
  comment: comment
  'hidden-link:${applicationInsightsId}': 'Resource'
}
var tags = union(referential, specificTags)

// === RESOURCES ===

@description('Availability test')
resource availabilityTest 'Microsoft.Insights/webtests@2018-05-01-preview' = { // @2020-10-05-preview is not available in westeurope
  name: availabilityTestName
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
    Kind: 'standard'
    RetryEnabled: true
    Locations: [ for testLocation in testLocations: {
      Id: testLocation
    }]
    Request: {
      RequestUrl: targetUrl
      HttpVerb: 'GET'
      Headers: null
      RequestBody: null
      FollowRedirects: true
    }
    ValidationRules: {
      ExpectedHttpStatusCode: 200
      IgnoreHttpsStatusCode: false
      ContentValidation: null
      SSLCheck: true
      SSLCertRemainingLifetimeCheck: 7
    }
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = availabilityTest.id

@description('The API Version of the deployed resource')
output apiVersion string = availabilityTest.apiVersion

@description('The Name of the deployed resource')
output name string = availabilityTest.name
