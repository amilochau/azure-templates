/*
  Deploy a CDN custom domain
*/

// === PARAMETERS ===

@description('The naming convention, from the conventions.json file')
#disable-next-line no-unused-params
param conventions object

@description('The name of the CDN endpoint')
param cdnEndpointName string

@description('The application custom domain')
param customDomain string

// === VARIABLES ===

//var rootDomain = indexOf(customDomain, '.') == lastIndexOf(customDomain, '.') ? customDomain : substring(customDomain, indexOf(customDomain, '.') + 1)

// === EXISTING ===

@description('The CDN endpoint')
resource cdnEndpoint 'Microsoft.Cdn/profiles/endpoints@2021-06-01' existing = {
  name: cdnEndpointName
}

// === RESOURCES ===

/*@description('CNAME record for custom domains')
module dnsRecord '../networking/dns-cname-record.bicep' = {
  name: 'Resource-CnameRecord-${customDomain}'
  scope: resourceGroup(conventions.global.dnsZone[rootDomain])
  params: {
    customDomain: customDomain
    target: swa.properties.defaultHostname
  }
}*/

@description('Custom domains for Static Web Apps')
resource swaDomain 'Microsoft.Cdn/profiles/endpoints/customDomains@2021-06-01' = {
  name: customDomain
  parent: cdnEndpoint
  /*dependsOn: [
    dnsRecord
  ]*/
  properties: {
    hostName: customDomain
    // isDefault: isDefault // Not documented from API but useful - it does not work on first deployment...
  }
}
