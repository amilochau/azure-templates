/*
  Deploy an Application Insights
  Resources deployed from this template:
    - Application Insights
  Required parameters:
    - `referential`
    - `disableLocalAuth`
    - `dailyCap`
    - `workspaceId`
  Optional parameters:
    [None]
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
    - `instrumentationKey`
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('Disable non-AAD based authentication to publish metrics')
param disableLocalAuth bool = false

@description('Daily data ingestion cap, in GB/d')
param dailyCap string

@description('Workspace ID')
param workspaceId string

// === VARIABLES ===

var location = resourceGroup().location
var aiName = '${referential.organization}-${referential.application}-${referential.host}-ai'

// === RESOURCES ===

// Application Insights
resource ai 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: aiName
  location: location
  kind: 'web'
  tags: referential
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
output instrumentationKey string = ai.properties.InstrumentationKey
