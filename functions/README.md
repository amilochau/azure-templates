# Readme - functions

## Introduction

`amilochau/azure-templates/functions/template.bicep` is a Bicep template developed to manage infrastructure for an application running with Azure Functions, Storage, Service Bus, Application Insights, Key Vault and App Configuration .

---

## Usage

Use this Bicep template if you want to deploy infrastructure for an Azure Functions application. This template works well with applications that reference `Milochau.Core.Functions` framework.

You can safely use this template in an IaC automated process, such as a GitHub workflow.

### Template parameters

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "organizationPrefix": {
      "value": "abc"
    },
    "applicationName": {
      "value": "appname"
    },
    "environmentName": {
      "value": "Production"
    },
    "hostName": {
      "value": "prd"
    },
    "appConfigurationName": {
      "value": "abc-config"
    },
    "appConfigurationResourceGroup": {
      "value": "abc-rg"
    },
    "monitoring": {
      "value": {
        "enableApplicationInsights": true,
        "disableLocalAuth": true
        "dailyCap": "1"
      }
    },
    "useKeyVault": {
      "value": true
    },
    "serviceBusQueues": {
      "value": [
        "queue1",
        "queue2"
      ]
    },
    "storageAccounts": {
      "value": [
        {
          "number": "1",
          "containers": [
            "container1",
            "container2"
          ],
          "readOnly": true,
          "daysBeforeDeletion": 365
        }
      ]
    }
  }
}
```
