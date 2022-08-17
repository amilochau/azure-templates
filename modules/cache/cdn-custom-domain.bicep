/*
  Deploy a CDN custom domain
*/

// === PARAMETERS ===

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The name of the CDN profile')
param cdnProfileName string

@description('The name of the CDN endpoint')
param cdnEndpointName string

@description('The application custom domain')
param customDomain string

// === VARIABLES ===

var rootDomain = indexOf(customDomain, '.') == lastIndexOf(customDomain, '.') ? customDomain : substring(customDomain, indexOf(customDomain, '.') + 1)

// === EXISTING ===

@description('The CDN endpoint')
resource cdnEndpoint 'Microsoft.Cdn/profiles/endpoints@2021-06-01' existing = {
  name: '${cdnProfileName}/${cdnEndpointName}'
}

// === RESOURCES ===

@description('CNAME record for custom domains')
module dnsRecord '../networking/cdn-dns-cname-record.bicep' = {
  name: 'Resource-CnameRecord-${customDomain}'
  scope: resourceGroup(conventions.global.dnsZone[rootDomain])
  params: {
    customDomain: customDomain
    target: 'cdnverify.${cdnEndpoint.properties.hostName}'
    cdnEndpointId: cdnEndpoint.id
  }
}

@description('Custom domains for CDN endpoint')
resource cdnEndpointDomain 'Microsoft.Cdn/profiles/endpoints/customDomains@2021-06-01' = {
  name: replace(customDomain, '.', '-')
  parent: cdnEndpoint
  dependsOn: [
    dnsRecord
  ]
  properties: {
    hostName: customDomain
  }
}
