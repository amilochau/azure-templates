# Readme - azure-templates

## Introduction

`azure-templates` is a set of Bicep templates developed to help creating Azure infrastructure for `amilochau` projects.

## Getting Started

1. Installation process
From your local computer, clone the repository.

2. Integration process
Please follow the development good practices, then follow the integration process.

---

## IaC Templates

The following templates are proposed for Infrastructure as Code, and can be freely used:

| Path | Usage | Readme |
| ---- | ----- | ------ |
| `amilochau/azure-templates/functions/template.bicep` | Create infrastructure for an application running with Azure Functions, Storage, CDN, Service Bus, Application Insights, Key Vault and App Configuration | [README.md](./functions/README.md) |
| `amilochau/azure-templates/functions/local-dependencies.bicep` | Create infrastructure for a local application using Storage, CDN, Service Bus and Key Vault | [README.md](./functions/README.md) |
| `amilochau/azure-templates/functions/api-registration.bicep` | Register an application as an API Management backend | [README.md](./functions/README.md) |
| `amilochau/azure-templates/configuration/template.bicep` | Create infrastructure for configuration with App Configuration | [README.md](./configuration/README.md) |
| `amilochau/azure-templates/monitoring/template.bicep` | Create infrastructure for monitoring with Log Analytics Workspace | [README.md](./monitoring/README.md) |
| `amilochau/azure-templates/gateway/template.bicep` | Create infrastructure for requests gateway with API Management | [README.md](./gateway/README.md) |
| `amilochau/azure-templates/static-web-apps/template.bicep` | Create infrastructure for an application running with Azure Static Web Apps | [README.md](./static-web-apps/README.md) |

### Run manually

These commands can help you run the Bicep templates manually, thanks to `azure cli`:

- `az bicep build --file $templateFile`: builds a Bicep template into ARM template
- `az group create --name $resourceGroupName --location $location`: creates or updates an Azure resource group
- `az deployment group create --resource-group $resourceGroupName --template-file $templateFile --parameters $parametersFile --confirm-with-what-if`: creates a new infrastructure deployment into Azure, after an interactive 'what if' check
- `az deployment group what-if --resource-group $resourceGroupName --template-file $templateFile --parameters $parametersFile`: executes a deployment What-If operation at resource group scope
