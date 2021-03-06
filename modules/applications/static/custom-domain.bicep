/*
  Deploy a Static Web Apps custom domain
*/

// === PARAMETERS ===

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The name of the Static Web Apps')
param swaName string

@description('The application custom domain')
param customDomain string

// === VARIABLES ===

var rootDomain = indexOf(customDomain, '.') == lastIndexOf(customDomain, '.') ? customDomain : substring(customDomain, indexOf(customDomain, '.') + 1)

// === EXISTING ===

@description('The Static Web Apps')
resource swa 'Microsoft.Web/staticSites@2021-02-01' existing = {
  name: swaName
}

// === RESOURCES ===

@description('CNAME record for custom domains')
module dnsRecord '../../networking/dns-cname-record.bicep' = {
  name: 'Resource-CnameRecord-${customDomain}'
  scope: resourceGroup(conventions.global.dnsZone[rootDomain])
  params: {
    customDomain: customDomain
    target: swa.properties.defaultHostname
  }
}

@description('Custom domains for Static Web Apps')
resource swaDomain 'Microsoft.Web/staticSites/customDomains@2021-02-01' = {
  name: customDomain
  parent: swa
  dependsOn: [
    dnsRecord
  ]
  properties: {
    // isDefault: isDefault // Not documented from API but useful - it does not work on first deployment...
  }
}
