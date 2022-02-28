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

@description('The deployment location')
param location string

// === RESOURCES ===

@description('Service Bus Namespace')
resource sbn 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.serviceBusNamespace}'
  location: location
  sku: {
    name: 'Basic'
  }
  tags: referential
  properties: {
    zoneRedundant: false
    disableLocalAuth: true
  }

  // Service Bus Queues
  resource queues 'queues@2021-11-01' = [for queue in serviceBusQueues: if (length(serviceBusQueues) > 0) {
    name: empty(serviceBusQueues) ? 'empty' : queue
    properties: {
      lockDuration: 'PT30S'
      maxSizeInMegabytes: 1024
      requiresDuplicateDetection: false
      requiresSession: false
      defaultMessageTimeToLive: 'P14D'
      deadLetteringOnMessageExpiration: true
      enableBatchedOperations: true
      duplicateDetectionHistoryTimeWindow: 'PT10M'
      maxDeliveryCount: 10
      enablePartitioning: false
      enableExpress: false
    }
  }]
}

// === OUTPUTS ===

@description('The ID of the deployed Service Bus Namespace')
output id string = sbn.id

@description('The API Version of the deployed Service Bus Namespace')
output apiVersion string = sbn.apiVersion

@description('The Name of the deployed Service Bus Namespace')
output name string = sbn.name
