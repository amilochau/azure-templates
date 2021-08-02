# Readme - app-config

## Introduction

`amilochau/azure-templates/app-config/template.bicep` is a Bicep template developed to manage infrastructure for an App Configuration.

---

## Usage

Use this Bicep template if you want to deploy infrastructure for an Azure App Configuration.

You can safely use this template in an IaC automated process, such as a GitHub workflow.

### Template parameters

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "appConfigurationName": {
      "value": "abc-config"
    }
  }
}
```
