/*
  Deploy a CDN
  Resources deployed from this template:
    - CDN profile
    - CDN endpoint
  Required parameters:
    - `referential`
    - `conventions`
    - `storageAccountHostName`
    - `storageAccountComment`
  Optional parameters:
    - `storageAccountNumber`
    - `cdnCacheExpirationInDays`
  Optional parameters:
    [None]
  Outputs:
    - `id`
    - `apiVersion`
    - `name`
*/

// === PARAMETERS ===

@description('The referential from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The storage account host name')
param storageAccountHostName string

@description('The storage account comment')
param storageAccountComment string

@description('The storage account number')
param storageAccountNumber string = ''

@description('The CDN cache expiration in days')
@minValue(1)
@maxValue(360)
param cdnCacheExpirationInDays int = 360

// === VARIABLES ===

var location = resourceGroup().location
var cdnProfileName = empty(storageAccountNumber) ? conventions.naming.cdnProfile.name : '${conventions.naming.cdnProfile.name}-${storageAccountNumber}'
var cdnEndpointName = empty(storageAccountNumber) ? conventions.naming.cdnEndpoint.name : '${conventions.naming.cdnEndpoint.name}-${storageAccountNumber}'
var commentTag = {
  comment: storageAccountComment
}
var tags = union(referential, commentTag)

// === RESOURCES ===

@description('CDN Profile')
resource cdn 'Microsoft.Cdn/profiles@2020-09-01' = {
  name: cdnProfileName
  location: location
  tags: tags
  sku: {
    name: 'Standard_Microsoft'
  }

  // CDN Endpoint
  resource endpoint 'endpoints@2020-09-01' = {
    name: cdnEndpointName
    location: location
    tags: referential
    properties: {
      isHttpAllowed: true
      isHttpsAllowed: true
      isCompressionEnabled: true
      originHostHeader: storageAccountHostName
      queryStringCachingBehavior: 'IgnoreQueryString'
      contentTypesToCompress: json(loadTextContent('./content-types.json'))
      origins: [
        {
          name: replace(storageAccountHostName, '.', '-')
          properties: {
            hostName: storageAccountHostName
          }
        }
      ]
      deliveryPolicy: {
        rules: [
          {
            name: 'Global'
            order: 0
            actions: [
              {
                name: 'CacheExpiration'
                parameters: {
                  cacheBehavior: 'Override'
                  cacheType: 'All'
                  cacheDuration: '${cdnCacheExpirationInDays}.00:00:00'
                  '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleCacheExpirationActionParameters'
                }
              }
            ]
          }
        ]
      }
    }
  }
}

// === OUTPUTS ===

output id string = cdn.id
output apiVersion string = cdn.apiVersion
output name string = cdn.name
