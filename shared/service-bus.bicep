// Deploy a Service Bus namespace with a queue
// Resources deployed from this template:
//   - Service Bus namespace
// Optional parameters:
//   - `serviceBusNamespaceName`
// Outputs:
//   - `id`
//   - `apiVersion`
//   - `name`
//   - `primaryConnectionString`

// === PARAMETERS ===

@description('Service Bus namespace name')
param serviceBusNamespaceName string

@description('The Service Bus queues')
param serviceBusQueues array = []

@description('The Service Bus clients')
param serviceBusClients array = []

@description('Service Bus queue properties')
param serviceBusQueueProperties object = {
  lockDuration: 'PT30S'
  maxSizeInMegabytes: 1024
  requiresDuplicateDetection: false
  requiresSession: false
  defaultMessageTimeToLive: 'P14D'
  deadLetteringOnMessageExpiration: false
  enableBatchedOperations: true
  duplicateDetectionHistoryTimeWindow: 'PT10M'
  maxDeliveryCount: 10
  enablePartitioning: false
  enableExpress: false
}

@description('Is the current environment Development')
param isDevelopment bool

// === VARIABLES ===

var location = resourceGroup().location

// === RESOURCES ===

// Service Bus
resource bus 'Microsoft.ServiceBus/namespaces@2021-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    zoneRedundant: false
  }

  // Default queue for Developers
  resource queue_dev 'queues@2018-01-01-preview' = if (isDevelopment) {
    name: 'developers'
    properties: serviceBusQueueProperties
  }

  resource auth_dev 'AuthorizationRules@2017-04-01' = if (isDevelopment) {
    name: 'developers'
    properties: {
      rights: [
        'Listen'
        'Send'
      ]
    }
  }
}

// Service Bus - Authorization for owner application
resource auth_owner 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2017-04-01' = {
  name: 'owner-app'
  parent: bus
  properties: {
    rights: [
      'Listen'
      'Send'
    ]
  }
}

// Service Bus - Queues for owner application
resource queue_owner 'Microsoft.ServiceBus/namespaces/queues@2018-01-01-preview' = [for queue in serviceBusQueues: if (length(serviceBusQueues) > 0) {
  name: empty(serviceBusQueues) ? 'dummy' : queue
  parent: bus
  properties: serviceBusQueueProperties
}]

// Service Bus - Authorizations for clients
resource auth_clients 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2017-04-01' = [for client in serviceBusClients: if (length(serviceBusClients) > 0) {
  name: empty(serviceBusClients) ? 'dummy' : client
  parent: bus
  properties: {
    rights: [
      'Listen'
      'Send'
    ]
  }
}]

// === OUTPUTS ===

output id string = bus.id
output apiVersion string = bus.apiVersion
output name string = bus.name
output primaryConnectionString string = listKeys(auth_owner.id, auth_owner.apiVersion).primaryConnectionString
