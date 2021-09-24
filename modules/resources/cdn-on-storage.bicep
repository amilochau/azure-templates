/*
  Deploy a CDN
  Resources deployed from this template:
    - CDN profile
    - CDN endpoint
  Required parameters:
    - `referential`
    - `storageAccountHostName`
  Optional parameters:
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

@description('The storage account host name')
param storageAccountHostName string

@description('The CDN cache expiration in days')
@minValue(1)
@maxValue(360)
param cdnCacheExpirationInDays int = 360

// === VARIABLES ===

var location = resourceGroup().location
var cdnProfileName = '${referential.organization}-${referential.application}-${referential.host}-cdnprofile'
var cdnEndpointName = '${referential.organization}-${referential.application}-${referential.host}-cdnedp'

// === RESOURCES ===

// Key Vault
resource cdn 'Microsoft.Cdn/profiles@2020-09-01' = {
  name: cdnProfileName
  location: location
  tags: referential
  sku: {
    name: 'Standard_Microsoft'
  }

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
      contentTypesToCompress: [
        'application/eot'
        'application/font'
        'application/font-sfnt'
        'application/javascript'
        'application/json'
        'application/opentype'
        'application/otf'
        'application/pkcs7-mime'
        'application/truetype'
        'application/ttf'
        'application/vnd.ms-fontobject'
        'application/xhtml+xml'
        'application/xml'
        'application/xml+rss'
        'application/x-font-opentype'
        'application/x-font-truetype'
        'application/x-font-ttf'
        'application/x-httpd-cgi'
        'application/x-javascript'
        'application/x-mpegurl'
        'application/x-opentype'
        'application/x-otf'
        'application/x-perl'
        'application/x-ttf'
        'font/eot'
        'font/ttf'
        'font/otf'
        'font/opentype'
        'image/svg+xml'
        'text/css'
        'text/csv'
        'text/html'
        'text/javascript'
        'text/js'
        'text/plain'
        'text/richtext'
        'text/tab-separated-values'
        'text/xml'
        'text/x-script'
        'text/x-component'
        'text/x-java-source'
      ]
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
