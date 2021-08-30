// Deploy a Website (Functions)
// Resources deployed from this template:
//   - Website (Functions)
// Required parameters:
//   - `referential`
//   - `linuxFxVersion`
//   - `workerRuntime`
//   - `serverFarmId`
//   - `webJobsStorageAccountName`
//   - `webJobsStorageAccountKey`
// Optional parameters:
//   - `appConfigurationEndpoint`
//   - `aiInstrumentationKey`
//   - `serviceBusNamespaceName`
//   - `kvVaultUri`
// Outputs:
//   - `id`
//   - `apiVersion`
//   - `name`
//   - `principalId`

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The Linux App framework and version')
@allowed([
  'DOTNETCORE|3.1'
  'DOTNET|5.0'
  'DOTNET|6.0'
])
param linuxFxVersion string

@description('The Functions worker runtime')
@allowed([
  'dotnet'
  'dotnet-isolated'
])
param workerRuntime string

@description('The server farm ID')
param serverFarmId string

@description('The Azure WebJobs Storage Account name')
param webJobsStorageAccountName string

@description('The Azure WebJobs Storage Account key')
param webJobsStorageAccountKey string

@description('The App Configuration endpoint')
param appConfigurationEndpoint string = ''

@description('The Application Insights instrumentation key')
param aiInstrumentationKey string = ''

// TODO Not used anymore, keep it until stable major version
// @description('The Application Insights connection string')
// param aiConnectionString string = ''

// TODO Not used anymore, keep it until stable major version
// @description('The Service Bus connection string')
// param serviceBusConnectionString string = ''

@description('The Service Bus Namespace name')
param serviceBusNamespaceName string = ''

@description('The Key Vaylt vault URI')
param kvVaultUri string = ''

// === VARIABLES ===

var location = resourceGroup().location
var functionsAppName = '${referential.organization}-${referential.application}-${referential.host}-fn'

// === RESOURCES ===

// Website (Functions)
resource fn 'Microsoft.Web/sites@2021-01-01' = {
  name: functionsAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  tags: referential
  properties: {
    serverFarmId: serverFarmId
    reserved: true
    httpsOnly: true
    dailyMemoryTimeQuota: 10000
  }

  resource fn_config 'config@2021-01-01' = {
    name: 'web'
    properties: {
      linuxFxVersion: linuxFxVersion
      localMySqlEnabled: false
      http20Enabled: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
    }
  }

  resource fn_appsettings 'config@2021-01-01' = {
    name: 'appsettings'
    properties: {
      'APPINSIGHTS_INSTRUMENTATIONKEY': aiInstrumentationKey
      // 'APPLICATIONINSIGHTS_CONNECTION_STRING': aiConnectionString // TODO May not be necessary: https://docs.microsoft.com/en-us/azure/azure-functions/functions-app-settings#applicationinsights_connection_string
      'AZURE_FUNCTIONS_APPCONFIG_ENDPOINT': appConfigurationEndpoint
      'AZURE_FUNCTIONS_ORGANIZATION': referential.organization
      'AZURE_FUNCTIONS_APPLICATION': referential.application
      'AZURE_FUNCTIONS_ENVIRONMENT': referential.environment
      'AZURE_FUNCTIONS_HOST': referential.host
      'AZURE_FUNCTIONS_KEYVAULT_VAULT' : kvVaultUri
      'AzureWebJobsDisableHomepage': 'true' // Disable homepage
      'FUNCTIONS_EXTENSION_VERSION': '~3'
      'FUNCTIONS_WORKER_RUNTIME': workerRuntime
      'WEBSITE_ENABLE_SYNC_UPDATE_SITE': 'false'
      // 'SCALE_CONTROLLER_LOGGING_ENABLED': 'AppInsights:Verbose' // To log scale controller logics https://docs.microsoft.com/en-us/azure/azure-functions/configure-monitoring?tabs=v2#configure-scale-controller-logs
      // 'WEBSITE_RUN_FROM_PACKAGE' : '1' // For Windows
      'AzureWebJobsServiceBus__fullyQualifiedNamespace': serviceBusNamespaceName
      'AzureWebJobsStorage': 'DefaultEndpointsProtocol=https;AccountName=${webJobsStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${webJobsStorageAccountKey}' // Connection to technical storage account - still needed until https://github.com/Azure/functions-action/issues/94 is completed
      'AzureWebJobsStorage__accountName': webJobsStorageAccountName
    }
  }

  /* TODO Replaced by AzureWebJobsServiceBus__fullyQualifiedNamespace, keep it until the next major update
  resource fn_connectionstrings 'config@2021-01-01' = {
    name: 'connectionstrings'
    properties: {
      'ServiceBusConnectionString': {
        value: serviceBusConnectionString
        type: 'Custom'
      }
    }
  }
  */
}

// === OUTPUTS ===

output id string = fn.id
output apiVersion string = fn.apiVersion
output name string = fn.name
output principalId string = fn.identity.principalId
