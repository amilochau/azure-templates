/*
  Get references from an existing API Management
  Resources deployed from this template:
    [None]
  Required parameters:
    - `apiManagementName`
  Optional parameters:
    [None]
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
*/

// === PARAMETERS ===

@description('API Management name')
param apiManagementName string

// === EXISTING ===

// App Configuration
resource apim 'Microsoft.ApiManagement/service@2021-01-01-preview' existing = {
  name: apiManagementName
}

// === OUTPUTS ===

output id string = apim.id
output apiVersion string = apim.apiVersion
output name string = apim.name
