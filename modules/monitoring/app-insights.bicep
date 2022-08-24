/*
  Deploy an Application Insights
*/

// === PARAMETERS ===

@description('The referential, from the tags.bicep module')
param referential object

@description('The naming convention, from the conventions.json file')
param conventions object

@description('The pricing plan')
@allowed([
  'Free'    // The cheapest plan, can create some small fees
  'Basic'   // Basic use with default limitations
])
param pricingPlan string

@description('Disable non-AAD based authentication to publish metrics')
param disableLocalAuth bool = false

@description('The deployment location')
param location string

// === VARIABLES ===

var dailyCap = pricingPlan == 'Free' ? '0.1' : pricingPlan == 'Basic' ? '100' : 'ERROR' // in GB/d
var aiName = conventions.global.logAnalyticsWorkspace[referential.environment].name
var buildInRoles = loadJsonContent('../global/built-in-roles.json')

// === RESOURCES ===

@description('Log Analytics Workspace')
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
  scope: resourceGroup(conventions.global.logAnalyticsWorkspace[referential.environment].resourceGroupName)
  name: conventions.global.logAnalyticsWorkspace[referential.environment].name
}

@description('Application Insights')
resource ai 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: aiName
  location: location
  kind: 'web'
  tags: referential
  properties: {
    Application_Type: 'web'
    DisableLocalAuth: disableLocalAuth // true = Enforcing AAD as the only authentication method
    /* One main limitation to put this 'DisableLocalAuth' settings to 'true':
      1/ Functions application do not support RBAC authentication yet
    */
    WorkspaceResourceId: workspace.id
  }

  resource featuresCapabilities 'pricingPlans@2017-10-01' = {
    name: 'current'
    properties: {
      cap: any(dailyCap)
      planType: 'Basic'
    }
  }
}

@description('The action group for smart detection')
resource actionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: 'Application Insights Smart Detection'
  location: 'Global'
  tags: referential
  properties: {
    groupShortName: 'SmartDetect'
    enabled: true
    armRoleReceivers: [
      {
        name: 'Monitor Contributor'
        roleId: buildInRoles['Monitoring Contributor']
        useCommonAlertSchema: true
      }
      {
        name: 'Monitor Reader'
        roleId: buildInRoles['Monitoring Reader']
        useCommonAlertSchema: true
      }
    ]
  }
}

@description('The alert rule for failure anomalies')
resource smartDetectorAlertRule 'microsoft.alertsManagement/smartDetectorAlertRules@2021-04-01' = {
  name: 'Failure Anomalies - ${aiName}'
  location: 'Global'
  tags: referential
  properties: {
    state: 'Enabled'
    frequency: 'PT1M'
    severity: 'Sev2'
    scope: [
      ai.id
    ]
    actionGroups: {
      groupIds: [
        actionGroup.id
      ]
    }
    detector: {
      id: 'FailureAnomaliesDetector'
    }
  }
}

// === OUTPUTS ===

@description('The ID of the deployed resource')
output id string = ai.id

@description('The API Version of the deployed resource')
output apiVersion string = ai.apiVersion

@description('The Name of the deployed resource')
output name string = ai.name

@description('The Instrumentation Key of the deployed resource')
output instrumentationKey string = ai.properties.InstrumentationKey

@description('The Connection String of the deployed resource')
output connectionString string = ai.properties.ConnectionString
