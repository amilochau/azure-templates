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

@description('The CDN custom domains')
param cdnCustomDomains array = []

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
resource cdn 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: cdnProfileName
  location: location
  tags: tags
  sku: {
    name: 'Standard_Microsoft'
  }
}

@description('CDN Endpoint')
resource endpoint 'Microsoft.Cdn/profiles/endpoints@2021-06-01' = {
  name: cdnEndpointName
  parent: cdn
  location: location
  tags: referential
  properties: {
    isHttpAllowed: false
    isHttpsAllowed: true
    isCompressionEnabled: true
    originHostHeader: storageAccountHostName
    queryStringCachingBehavior: 'IgnoreQueryString'
    contentTypesToCompress: loadJsonContent('../global/cdn-content-types.json')
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
                typeName: 'DeliveryRuleCacheExpirationActionParameters'
              }
            }
          ]
        }
      ]
    }
  }
}

@description('Custom domains for CDN endpoint')
module domains 'cdn-custom-domain.bicep' = [for (customDomain, i) in cdnCustomDomains: if (!empty(cdnCustomDomains)) {
  name: empty(customDomain) ? 'empty' : 'Resource-CustomDomain-${customDomain}'
  params: {
    conventions: conventions
    customDomain: customDomain
    cdnProfileName: cdn.name
    cdnEndpointName: endpoint.name
  }
}]

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = cdn.id

@description('The API Version of the deployed resource')
output apiVersion string = cdn.apiVersion

@description('The Name of the deployed resource')
output name string = cdn.name
