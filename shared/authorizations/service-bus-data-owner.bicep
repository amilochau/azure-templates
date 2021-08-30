// Deploy authorizations for a Service Bus namespace
// Resources deployed from this template:
//   - Authorizations
// Required parameters:
//   - `principalId`
//   - `serviceBusNamespaceName`
// Optional parameters:
//   [None]
// Optional parameters:
//   [None]
// Outputs:
//   [None]

// === PARAMETERS ===

@description('Principal ID')
param principalId string

@description('Service Bus Namespace name')
param serviceBusNamespaceName string

// === VARIABLES ===

var roleDefinitionIds = {
  'Service Bus Data Owner': '090c5cfd-751d-490a-894a-3ce6f1109419'
}

// === EXISTING ===

// Roles
resource roleServiceBusDataOwner 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: roleDefinitionIds['Service Bus Data Owner']
}

// Service Bus Namespace
resource sbn 'Microsoft.ServiceBus/namespaces@2021-01-01-preview' existing = {
  name: serviceBusNamespaceName
}

// === AUTHORIZATIONS ===

// Principal to Storage account
resource auth_app_stg 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id, principalId, sbn.id)
  scope: sbn
  properties: {
    roleDefinitionId: roleServiceBusDataOwner.id
    principalId: principalId
  }
}
