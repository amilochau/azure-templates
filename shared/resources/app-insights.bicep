// Deploy an Application Insights
// Resources deployed from this template:
//   - Application Insights
// Required parameters:
//   - `aiName`
// Optional parameters:
//   - `disableLocalAuth`
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
  }
}

// === OUTPUTS ===

output id string = ai.id
output apiVersion string = ai.apiVersion
output name string = ai.name
output InstrumentationKey string = ai.properties.InstrumentationKey
output ConnectionString string = ai.properties.ConnectionString
