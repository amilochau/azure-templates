// Deploy a Service Bus namespace with a queue
// Resources deployed from this template:
//   - Service Bus Namespace
//   - Service Bus Queues
// Required parameters:
//   - `referential`
// Optional parameters:
//   - `serviceBusQueues`
//   - `serviceBusQueueProperties`
// Outputs:
//   - `id`
//   - `apiVersion`
//   - `name`
//   - `primaryConnectionString`

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

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
var serviceBusNamespaceName = '${referential.organization}-${referential.application}-${referential.host}-bus'

// === RESOURCES ===

// Service Bus Namespace
resource sbn 'Microsoft.ServiceBus/namespaces@2021-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Basic'
  }
  tags: referential
  properties: {
    zoneRedundant: false
  }
}

// Service Bus - Authorization for owner application
resource auth_owner 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2017-04-01' = {
  name: 'owner-app'
  parent: sbn
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
  parent: sbn
  properties: serviceBusQueueProperties
}]

// === OUTPUTS ===

output id string = sbn.id
output apiVersion string = sbn.apiVersion
output name string = sbn.name
output primaryConnectionString string = listKeys(auth_owner.id, auth_owner.apiVersion).primaryConnectionString
