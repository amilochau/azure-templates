var applicationName = 'mil-tripsapi-dev-fn'
var location = resourceGroup().location
param deploymentDate string = utcNow()

@description('Script to get current WEBSITE_RUN_FROM_PACKAGE appsettings value')
resource appsettingsScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'Script-fn-appsettings-WEBSITE_RUN_FROM_PACKAGE'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/01234567-89AB-CDEF-0123-456789ABCDEF/resourcegroups/deploymenttest/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myscriptingid': {}
    }
  }
  properties: {
    forceUpdateTag: deploymentDate
    azCliVersion: '2.30.0' // From https://mcr.microsoft.com/v2/azure-cli/tags/list, even if this list is not deployed as fast as we should expect
    arguments: '-applicationName ${applicationName}'
    scriptContent: '''
      param([string] $applicationName)
      Write-Output "Application name: $applicationName"
      $DeploymentScriptOutputs = @{}
      $DeploymentScriptOutputs[\'TEST\'] = "TESTVALUE-$applicationName"
    '''
    cleanupPreference: 'Always'
    retentionInterval: 'PT1H'
  }
}
