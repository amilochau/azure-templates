// Deploy an Application Insights
// Resources deployed from this template:
//   - Application Insights
// Required parameters:
//   - `organizationName`
//   - `applicationName`
//   - `environmentName`
//   - `hostName`
//   - `disableLocalAuth`
//   - `dailyCap`
//   - `workspaceId`
// Optional parameters:
//   [None]
// Outputs:
//   - `id`
//   - `apiVersion`
//   - `name`
//   - `InstrumentationKey`
//   - `ConnectionString`

// === PARAMETERS ===

@description('The organization name')
param organizationName string

@description('The application name')
param applicationName string

@description('The environment name of the deployment stage')
param environmentName string

@description('The host name of the deployment stage')
param hostName string


@description('Disable non-AAD based authentication to publish metrics')
param disableLocalAuth bool = false

@description('Daily data ingestion cap, in GB/d')
param dailyCap string

@description('Workspace ID')
param workspaceId string

// === VARIABLES ===

var location = resourceGroup().location
var aiName = '${organizationName}-${applicationName}-${hostName}-ai'

// === RESOURCES ===

// Application Insights
resource ai 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: aiName
  location: location
  kind: 'web'
  tags:{
    organization: organizationName
    application: applicationName
    environment: environmentName
    host: hostName
  }
  properties: {
    Application_Type: 'web'
    DisableLocalAuth: disableLocalAuth
    WorkspaceResourceId: workspaceId
  }

  resource featuresCapabilities 'pricingPlans@2017-10-01' = {
    name: 'current'
    properties: {
      cap: json(dailyCap)
      planType: 'Basic'
    }
  }
}

// === OUTPUTS ===

output id string = ai.id
output apiVersion string = ai.apiVersion
output name string = ai.name
output InstrumentationKey string = ai.properties.InstrumentationKey
output ConnectionString string = ai.properties.ConnectionString
