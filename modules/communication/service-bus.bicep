/*
  Deploy a Service Bus namespace with its queues
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The Service Bus queues')
param serviceBusQueues array = []

// === VARIABLES ===

var location = resourceGroup().location

// === RESOURCES ===

@description('Service Bus Namespace')
resource sbn 'Microsoft.ServiceBus/namespaces@2021-01-01-preview' = {
  name: conventions.naming.serviceBusNamespace.name
  location: location
  sku: {
    name: 'Basic'
  }
  tags: referential
  properties: {
    zoneRedundant: false
  }
}

@description('Service Bus Queues')
resource queues 'Microsoft.ServiceBus/namespaces/queues@2018-01-01-preview' = [for queue in serviceBusQueues: if (length(serviceBusQueues) > 0) {
  name: empty(serviceBusQueues) ? 'empty' : queue
  parent: sbn
  properties: {
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
}]

// === OUTPUTS ===

output id string = sbn.id
output apiVersion string = sbn.apiVersion
output name string = sbn.name
