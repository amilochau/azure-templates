/*
  Deploy a Monitor Workbook
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The Log Analytics workspace id')
param workspaceId string

@description('The deployment location')
param location string

// === VARIABLES ===

var workbookData = loadJsonContent('../global/workbooks/applications.json')

// === RESOURCES ===

resource workbook 'Microsoft.Insights/workbooks@2022-04-01' = {
  name: guid('${conventions.naming.prefix}${conventions.naming.suffixes.monitorWorkbook}-apps')
  location: location
  tags: referential
  kind: 'shared'
  properties: {
    displayName: 'Applications Monitoring'
    category: 'workbook'
    sourceId: workspaceId
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
