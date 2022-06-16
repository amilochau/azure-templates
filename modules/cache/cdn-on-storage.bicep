/*
  Deploy a CDN profile and endpoint
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

@description('The storage account suffix')
param storageAccountSuffix string = ''

@description('The CDN cache expiration in days')
@minValue(1)
@maxValue(360)
param cdnCacheExpirationInDays int = 360

@description('The deployment location')
param location string

// === VARIABLES ===

var cdnProfileName = '${conventions.naming.prefix}${conventions.naming.suffixes.cdnProfile}${storageAccountSuffix}'
var cdnEndpointName = '${conventions.naming.prefix}${conventions.naming.suffixes.cdnEndpoint}${storageAccountSuffix}'
var specificTags = {
  comment: storageAccountComment
}
var tags = union(referential, specificTags)

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
  resource endpoint 'endpoints' = {
    name: cdnEndpointName
    location: location
    tags: referential
    properties: {
      isHttpAllowed: false
      isHttpsAllowed: true
      isCompressionEnabled: true
      originHostHeader: storageAccountHostName
      queryStringCachingBehavior: 'IgnoreQueryString'
      contentTypesToCompress: loadJsonContent('./content-types.json')
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

@description('The ID of the deployed resource')
output id string = cdn.id

@description('The API Version of the deployed resource')
output apiVersion string = cdn.apiVersion

@description('The Name of the deployed resource')
output name string = cdn.name
