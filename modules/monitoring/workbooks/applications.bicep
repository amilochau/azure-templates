/*
  Deploy a Monitor Workbook
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The deployment location')
param location string

// === VARIABLES ===

var workbookData = loadJsonContent('./applications.json')
var workbookDisplayNamePrefix = 'Applications Monitoring'
var workbookDisplayName = referential.environment == 'Production' ? workbookDisplayNamePrefix : '${workbookDisplayNamePrefix} (${referential.host})'

// === RESOURCES ===

resource workbook 'Microsoft.Insights/workbooks@2022-04-01' = {
  name: guid('${conventions.naming.prefix}${conventions.naming.suffixes.monitorWorkbook}-apps')
  location: location
  tags: referential
  kind: 'shared'
  properties: {
    displayName: workbookDisplayName
    category: 'workbook'
    serializedData: string(workbookData)
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = workbook.id

@description('The API Version of the deployed resource')
output apiVersion string = workbook.apiVersion

@description('The Name of the deployed resource')
output name string = workbook.name
