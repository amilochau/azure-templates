/*
  Deploy a custom domain as a DNS CNAME record
*/

// === PARAMETERS ===

@description('The custom domain')
param customDomain string

@description('The target of the CNAME record')
param target string

@description('The id of the CDN endpoint')
param cdnEndpointId string

// === VARIABLES ===

var isRootDomain = indexOf(customDomain, '.') == lastIndexOf(customDomain, '.') && indexOf(customDomain, '.') != -1
var domain = isRootDomain ? customDomain : substring(customDomain, indexOf(customDomain, '.') + 1)
var aliasRecordName = isRootDomain ? 'cdnverify' : 'cdnverify.${substring(customDomain, 0, length(customDomain) - length(domain) - 1)}'
var aliasRecordSetName = isRootDomain ? 'www' : substring(customDomain, 0, length(customDomain) - length(domain) - 1)

// === EXISTING ===

@description('The DNS zone')
resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: domain
}

// === RESOURCES ===

@description('The CNAME record')
resource cnameRecord 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  name: aliasRecordName
  parent: dnsZone
  properties: {
    TTL: 3600
    CNAMERecord: {
      cname: target
    }
  }
}

@description('The A record for target resource')
resource aRecordSet 'Microsoft.Network/dnsZones/A@2018-05-01' = if (isRootDomain) {
  name: '@'
  parent: dnsZone
  properties: {
    TTL: 3600
    targetResource: {
      id: cdnEndpointId
    }
  }
}

@description('The CNAME record for target resource')
resource cnameRecordSet 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = if (!isRootDomain) {
  name: aliasRecordSetName
  parent: dnsZone
  properties: {
    TTL: 3600
    targetResource: {
      id: cdnEndpointId
    }
  }
}
