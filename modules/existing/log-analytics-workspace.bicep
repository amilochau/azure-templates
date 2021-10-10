/*
  Deploy an Log Analytics Workspace
  Resources deployed from this template:
    - Log Analytics Workspace
  Required parameters:
    - `workspaceName`
    - `workspaceResourceGroupName`
  Optional parameters:
    [None]
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
*/

// === PARAMETERS ===

@description('The Log Analytics workspace name')
param workspaceName string

@description('The Log Analytics workspace resource group name')
param workspaceResourceGroupName string

// === RESOURCES ===

// Log Analytics Workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  scope: resourceGroup(workspaceResourceGroupName)
  name: workspaceName
}

// === OUTPUTS ===

output id string = workspace.id
output apiVersion string = workspace.apiVersion
output name string = workspace.name
