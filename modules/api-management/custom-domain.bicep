/*
  Deploy an API Management custom domain
*/

// === PARAMETERS ===

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The name of the API Management')
param apiManagementName string

@description('The custom domain')
param customDomain string

// === VARIABLES ===

var rootDomain = indexOf(customDomain, '.') == lastIndexOf(customDomain, '.') ? customDomain : substring(customDomain, indexOf(customDomain, '.') + 1)

// === EXISTING ===

@description('The API Management')
resource cdnEndpoint 'Microsoft.ApiManagement/service@2021-12-01-preview' existing = {
  name: apiManagementName
}

// === RESOURCES ===

@description('CNAME record for custom domains')
module dnsRecord '../networking/cdn-dns-records.bicep' = {
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
