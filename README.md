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
| `amilochau/azure-templates/functions/template.bicep@main` | Create infrastructure for an application running with Azure Functions, Storage, Service Bus, Application Insights, Key Vault and App Configuration | [README.md](./functions/README.md) |
| `amilochau/azure-templates/app-config/template.bicep@main` | Create infrastructure for an App Configuration | [README.md](./app-config/README.md) |

### Run manually

These commands can help you run the Bicep templates manually, thanks to `azure cli`:

- `az bicep build --file $templateFile`: builds a Bicep template into ARM template
- `az group create --name $resourceGroupName --location $location`: creates or updates an Azure resource group
- `az deployment group create --resource-group $resourceGroupName --template-file $templateFile --parameters $parametersFile --confirm-with-what-if`: creates a new infrastructure deployment into Azure, after an interactive 'what if' check
