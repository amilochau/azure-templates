/*
  Deploy an Log Analytics Workspace
  Resources deployed from this template:
    - Log Analytics Workspace
  Required parameters:
    - `workspaceName`
    - `workspaceResourceGroup`
  Optional parameters:
    [None]
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
*/

// === PARAMETERS ===

@description('Log Analytics Workspace name')
param workspaceName string

@description('Log Analytics Workspace resource group')
param workspaceResourceGroup string

// === RESOURCES ===

// Log Analytics Workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  scope: resourceGroup(workspaceResourceGroup)
  name: workspaceName
}

// === OUTPUTS ===

output id string = workspace.id
output apiVersion string = workspace.apiVersion
output name string = workspace.name
