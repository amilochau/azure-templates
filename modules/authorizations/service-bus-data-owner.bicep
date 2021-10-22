/*
  Deploy authorizations for a Service Bus namespace
  Resources deployed from this template:
    - Authorizations
  Required parameters:
    - `principalId`
    - `serviceBusNamespaceName`
    - `roleDescription`
  Optional parameters:
    [None]
  Optional parameters:
    [None]
  Outputs:
    [None]
*/

// === PARAMETERS ===

@description('Principal ID')
param principalId string

@description('Service Bus Namespace name')
param serviceBusNamespaceName string

@description('The role description')
param roleDescription string

// === VARIABLES ===

var buildInRoles = json(loadTextContent('./build-in-roles.json'))

// === EXISTING ===

@description('Role - Service Bus Data Owner')
resource roleServiceBusDataOwner 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: buildInRoles['Service Bus Data Owner']
}

@description('Service Bus Namespace')
resource sbn 'Microsoft.ServiceBus/namespaces@2021-01-01-preview' existing = {
  name: serviceBusNamespaceName
}

// === AUTHORIZATIONS ===

@description('Principal to Storage account')
resource auth_app_stg 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(principalId, sbn.id, roleServiceBusDataOwner.id)
  scope: sbn
  properties: {
    roleDefinitionId: roleServiceBusDataOwner.id
    principalId: principalId
    description: roleDescription
  }
}
