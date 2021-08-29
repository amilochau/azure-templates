# Readme - gateway

## Introduction

`amilochau/azure-templates/diagnostics/template.bicep` is a Bicep template developed to manage infrastructure for requests gateway running with API Management.

---

## Usage

Use this Bicep template if you want to deploy infrastructure for an API Management.

You can safely use this template in an IaC automated process, such as a GitHub workflow.

### Template parameters

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "organizationName": {
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
    "api": {
      "value": {
        "publisherEmail": "john@example.com",
        "publisherName": "John"
      }
    },
    "monitoring": {
      "value": {
        "enableApplicationInsights": true,
        "disableLocalAuth": true,
        "dailyCap": "1",
        "workspaceName": "",
        "workspaceResourceGroup": ""
      }
    }
  }
}
```
