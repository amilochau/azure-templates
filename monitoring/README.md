# Readme - monitoring

## Introduction

`amilochau/azure-templates/monitoring/template.bicep` is a Bicep template developed to manage infrastructure for monitoring running with Log Analytics Workspace.

---

## Usage

Use this Bicep template if you want to deploy infrastructure to monitoring Azure resources.

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
    "dailyCap": {
      "value": "1"
    }
  }
}
```
