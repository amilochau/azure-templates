// Get references from an existing Application Insights
// Resources deployed from this template:
//   [None]
// Required parameters:
//   - `appInsightsName`
// Optional parameters:
//   [None]
// Outputs:
//   - `id`
//   - `apiVersion`
//   - `name`
//   - `InstrumentationKey`

// === PARAMETERS ===

@description('The Application Insights name')
param appInsightsName string

// === EXISTING ===

// Application Insights
resource ai 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: appInsightsName
}

// === OUTPUTS ===

output id string = ai.id
output apiVersion string = ai.apiVersion
output name string = ai.name
output InstrumentationKey string = ai.properties.InstrumentationKey
