/*
  Deploy a custom domain as a DNS CNAME record
*/

// === PARAMETERS ===

@description('The custom domain')
param customDomain string

@description('The target of the CNAME record')
param target string

@description('The domain registration idenfitier of the TXT record')
param domainRegistrationIdentifier string

// === VARIABLES ===

@description('Whether the customDomain is a root domain')
var isRootDomain = indexOf(customDomain, '.') == lastIndexOf(customDomain, '.') && indexOf(customDomain, '.') != -1

@description('The domain (with its extension)')
var domain = isRootDomain ? customDomain : substring(customDomain, indexOf(customDomain, '.') + 1)

@description('The subdomain')
var subdomain = isRootDomain ? '' : substring(customDomain, 0, indexOf(customDomain, '.'))

var aliasRecordName = isRootDomain ? 'www' : subdomain

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

@description('The TXT record')
resource txtRecord 'Microsoft.Network/dnsZones/TXT@2018-05-01' = {
  name: 'apimuid.${aliasRecordName}'
  parent: dnsZone
  properties: {
    TTL: 3600
    TXTRecords: [
      {
        value: [
          domainRegistrationIdentifier
        ]
      }
    ]
  }
}
