/*
  Deploy a policies Initiative with its assignment
*/

targetScope = 'managementGroup'

// === VARIABLES ===

var policysetName = 'custom-policyset-security'
var policysetProperties = loadJsonContent('./policyset.json', 'properties')

// === RESOURCES ===

@description('The policy set definition')
resource policyset 'Microsoft.Authorization/policySetDefinitions@2021-06-01' = {
  name: policysetName
  properties: policysetProperties
}

@description('The policy set assignment')
resource assignment 'Microsoft.Authorization/policyAssignments@2021-06-01' = {
  name: guid(policysetName)
  properties: {
    displayName: policysetProperties.displayName
    description: policysetProperties.description
    enforcementMode: 'Default'
    policyDefinitionId: policyset.id
  }
}
