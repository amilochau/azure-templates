/*
  Deploy a Static Web Apps custom domain
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The name of the Static Web Apps')
param swaName string

@description('The custom domain')
param customDomain string

// === VARIABLES ===

var rootDomain = indexOf(customDomain, '.') == lastIndexOf(customDomain, '.') ? customDomain : substring(customDomain, indexOf(customDomain, '.') + 1)
var dnsZone = loadJsonContent('../../global/organization-specifics/dns-zones.json')[rootDomain]
var isRootDomain = indexOf(customDomain, '.') == lastIndexOf(customDomain, '.') && indexOf(customDomain, '.') != -1

// === EXISTING ===

@description('The Static Web Apps')
resource swa 'Microsoft.Web/staticSites@2021-03-01' existing = {
  name: swaName
}

// === RESOURCES ===

@description('CNAME record for custom domains')
module dnsRecord '../../networking/swa-dns-records.bicep' = {
  name: 'Resource-CnameRecord-${customDomain}'
  scope: resourceGroup(dnsZone.resourceGroup)
  params: {
    referential: referential
    customDomain: customDomain
    target: swa.properties.defaultHostname
    swaId: swa.id
  }
}

@description('Custom domains for Static Web Apps')
resource swaDomain 'Microsoft.Web/staticSites/customDomains@2021-03-01' = {
  name: customDomain
  parent: swa
  dependsOn: [
    dnsRecord
  ]
  properties: {
    validationMethod: isRootDomain ? 'dns-txt-token' : 'cname-delegation'
    // isDefault: isDefault // Not documented from API but useful - it does not work on first deployment...
  }
}
