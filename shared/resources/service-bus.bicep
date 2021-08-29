// Deploy a Service Bus namespace with a queue
// Resources deployed from this template:
//   - Service Bus namespace
// Required parameters:
//   [None]
// Optional parameters:
//   - `serviceBusQueues`
//   - `serviceBusQueueProperties`
// Outputs:
//   - `id`
//   - `apiVersion`
//   - `name`
//   - `primaryConnectionString`

// === PARAMETERS ===

@description('The Service Bus queues')
param serviceBusQueues array = []

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

// === VARIABLES ===

var location = resourceGroup().location
var tags = resourceGroup().tags
var serviceBusNamespaceName = '${tags.organization}-${tags.application}-${tags.host}-bus'

// === RESOURCES ===

// Service Bus
resource bus 'Microsoft.ServiceBus/namespaces@2021-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Basic'
  }
  tags: resourceGroup().tags
  properties: {
    zoneRedundant: false
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

// === OUTPUTS ===

output id string = bus.id
output apiVersion string = bus.apiVersion
output name string = bus.name
output primaryConnectionString string = listKeys(auth_owner.id, auth_owner.apiVersion).primaryConnectionString
