// Deploy an Application Insights
// Resources deployed from this template:
//   - Application Insights
// Required parameters:
//   - `aiName`
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

@description('Application Insights name')
param aiName string

@description('Disable non-AAD based authentication to publish metrics')
param disableLocalAuth bool = false

@description('Daily data ingestion cap, in GB/d')
param dailyCap string

@description('Workspace ID')
param workspaceId string

// === VARIABLES ===

var location = resourceGroup().location

// === RESOURCES ===

// Application Insights
resource ai 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: aiName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    DisableLocalAuth: disableLocalAuth
    WorkspaceResourceId: workspaceId
  }

  resource featuresCapabilities 'pricingPlans@2017-10-01' = {
    name: 'current'
    properties: {
      cap: json(dailyCap)
    }
  }
}

// === OUTPUTS ===

output id string = ai.id
output apiVersion string = ai.apiVersion
output name string = ai.name
output InstrumentationKey string = ai.properties.InstrumentationKey
output ConnectionString string = ai.properties.ConnectionString
