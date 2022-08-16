/*
  Deploy authorizations for a Service Bus namespace
*/

// === PARAMETERS ===

@description('Principal ID')
param principalId string

@description('Principal Type')
@allowed([
  'ServicePrincipal'
  'Group'
])
param principalType string = 'ServicePrincipal'

@description('Service Bus Namespace name')
param serviceBusNamespaceName string

@description('The role type')
@allowed([
  'Owner' // Recommended for most use cases
  'Receiver'
  'Sender'
])
param roleType string

@description('The role description')
param roleDescription string

// === VARIABLES ===

var buildInRoles = loadJsonContent('../../global/built-in-roles.json')
var roleName = roleType == 'Owner' ? buildInRoles['Service Bus Data Owner'] : roleType == 'Receiver' ? buildInRoles['Service Bus Data Receiver'] : buildInRoles['Service Bus Data Sender']

// === EXISTING ===

@description('Role')
resource role 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: roleName
}

@description('Service Bus Namespace')
resource sbn 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' existing = {
  name: serviceBusNamespaceName
}

// === AUTHORIZATIONS ===

@description('Principal to Storage account')
resource auth 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(principalId, sbn.id, role.id)
  scope: sbn
  properties: {
    roleDefinitionId: role.id
    principalId: principalId
    description: roleDescription
    principalType: principalType
  }
}
