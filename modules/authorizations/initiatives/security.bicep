/*
  Deploy a policies Initiative with its assignment
*/

targetScope = 'managementGroup'

// === VARIABLES ===

var policySetName = 'policyset-custom-security'
var policyAssignmentName = 'SecurityCustom'
var policySetProperties = loadJsonContent('./security.json').properties

// === RESOURCES ===

@description('The policy set definition')
resource policySet 'Microsoft.Authorization/policySetDefinitions@2021-06-01' = {
  name: policySetName
  properties: policySetProperties
}

@description('The policy set assignment')
resource assignment 'Microsoft.Authorization/policyAssignments@2021-06-01' = {
  name: policyAssignmentName
  properties: {
    displayName: policySetProperties.displayName
    description: policySetProperties.description
    enforcementMode: 'Default'
    policyDefinitionId: policySet.id
  }
}
