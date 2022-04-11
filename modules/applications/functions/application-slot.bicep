/*
  Deploy a Functions application slot
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The pricing plan')
@allowed([
  'Free'    // The cheapest plan, can create some small fees
  'Basic'   // Basic use with default limitations
])
param pricingPlan string

@description('The functions name')
param functionsName string

@description('The slot name')
param slotName string

@description('The ID of the User-Assigned Identity to use')
param userAssignedIdentityId string

@description('The application type')
@allowed([
  'isolatedDotnet6'
])
param applicationType string

@description('The server farm ID')
param serverFarmId string

@description('The Azure WebJobs Storage Account name')
param webJobsStorageAccountName string

@description('The App Configuration endpoint')
param appConfigurationEndpoint string = ''

@description('The Application Insights connection string')
param aiConnectionString string = ''

@description('The Service Bus Namespace name')
param serviceBusNamespaceName string = ''

@description('The Key Vault vault URI')
param kvVaultUri string = ''

@description('The application packages URI')
param applicationPackageUri string = ''

@description('The application secret names')
param applicationSecretNames array = []

@description('The deployment location')
param location string

// === VARIABLES ===

var dailyMemoryTimeQuota = pricingPlan == 'Free' ? '10000' : pricingPlan == 'Basic' ? '1000000' : 'ERROR' // in GB.s/d
var linuxFxVersion = applicationType == 'isolatedDotnet6' ? 'DOTNET-ISOLATED|6.0' : 'ERROR'

var secrets = [for secretName in applicationSecretNames: {
  name: secretName
  value: '@Microsoft.KeyVault(SecretUri=${kvVaultUri}secrets/${secretName}/)'
}]
var appSettings = concat([
  {
    name: 'AZURE_FUNCTIONS_ORGANIZATION'
    value: referential.organization
  }
  {
    name: 'AZURE_FUNCTIONS_APPLICATION'
    value: referential.application
  }
  {
    name: 'AZURE_FUNCTIONS_ENVIRONMENT'
    value: referential.environment
  }
  {
    name: 'AZURE_FUNCTIONS_HOST'
    value: slotName
  }
  {
    name: 'AZURE_FUNCTIONS_REGION'
    value: referential.region
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: applicationType == 'isolatedDotnet6' ? '~4' : 'ERROR'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: applicationType == 'isolatedDotnet6' ? 'dotnet-isolated' : 'ERROR'
  }
  {
    name: 'AzureWebJobsDisableHomepage'
    value: 'true'
  }
  {
    name: 'AzureWebJobsStorage__accountName'
    value: webJobsStorageAccountName
  }
  empty(aiConnectionString) ? [] : {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: aiConnectionString
  }
  empty(appConfigurationEndpoint) ? [] : {
    name: 'AZURE_FUNCTIONS_APPCONFIG_ENDPOINT'
    value: appConfigurationEndpoint
  }
  empty(kvVaultUri) ? [] : {
    name: 'AZURE_FUNCTIONS_KEYVAULT_VAULT'
    value: kvVaultUri
  }
  empty(serviceBusNamespaceName) ? [] : {
    name: 'AzureWebJobsServiceBus__fullyQualifiedNamespace'
    value: '${serviceBusNamespaceName}.servicebus.windows.net'
  }
  empty(applicationPackageUri) ?  [] :{
    name: 'WEBSITE_RUN_FROM_PACKAGE'
    value: applicationPackageUri
  }
  empty(applicationSecretNames) ? [] : secrets
])

// === EXISTING ===

@description('Functions application')
resource fn 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionsName
}

// === RESOURCES ===

@description('Functions application')
resource fnSlot 'Microsoft.Web/sites/slots@2021-03-01' = {
  name: slotName
  parent: fn
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  tags: referential
  properties: {
    serverFarmId: serverFarmId
    reserved: true
    httpsOnly: true
    dailyMemoryTimeQuota: json(dailyMemoryTimeQuota)
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      localMySqlEnabled: false
      http20Enabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: appSettings
    }
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = fnSlot.id

@description('The API Version of the deployed resource')
output apiVersion string = fnSlot.apiVersion

@description('The Name of the deployed resource')
output name string = fnSlot.name

@description('The default host name if the deployed resource')
output defaultHostName string = fnSlot.properties.defaultHostName
