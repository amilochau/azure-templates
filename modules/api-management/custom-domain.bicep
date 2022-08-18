/*
  Deploy an API Management custom domain
*/

// === PARAMETERS ===

//@description('The URL of the API Management services')
param apiManagementUrl string

@description('The custom domain')
param customDomain string

// === VARIABLES ===

var rootDomain = indexOf(customDomain, '.') == lastIndexOf(customDomain, '.') ? customDomain : substring(customDomain, indexOf(customDomain, '.') + 1)
var dnsZone = loadJsonContent('../global/organization-specifics/dns-zones.json')[rootDomain]

// === RESOURCES ===

@description('CNAME record for custom domains')
module dnsRecord '../networking/apim-dns-records.bicep' = {
  name: 'Resource-CnameRecord-${customDomain}'
  scope: resourceGroup(dnsZone.resourceGroup)
  params: {
    customDomain: customDomain
    target: apiManagementUrl
    domainRegistrationIdentifier: dnsZone.apiManagementOwnershipId
  }
}
