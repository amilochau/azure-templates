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

var workbookData = replace(string(loadJsonContent('../global/workbooks/general-monitoring.json')), '%WORKSPACE_ID%', workspaceId)

// === RESOURCES ===

resource workbook 'Microsoft.Insights/workbooks@2022-04-01' = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.monitorWorkbook}-general-monitoring'
  location: location
  tags: referential
  kind: 'shared'
  properties: {
    displayName: 'General Monitoring'
    category: 'workbook'
    sourceId: workspaceId
    serializedData: workbookData
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = workbook.id

@description('The API Version of the deployed resource')
output apiVersion string = workbook.apiVersion

@description('The Name of the deployed resource')
output name string = workbook.name
