<p align="center">
  <a href="https://github.com/amilochau/azure-templates/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/amilochau/azure-templates" alt="License">
  </a>
  <a href="https://github.com/amilochau/azure-templates/releases">
    <img src="https://img.shields.io/github/v/release/amilochau/azure-templates" alt="Release">
  </a>
</p>
<h1 align="center">
  amilochau/azure-templates
</h1>

`azure-templates` is a set of Bicep templates developed to help creating Azure infrastructure for `amilochau` projects.

## What's new

You can find the new releases on the [GitHub releases page](https://github.com/amilochau/azure-templates/releases).

---

## IaC Templates

The following templates are proposed for Infrastructure as Code, and can be freely used:

| Path | Usage | Readme |
| ---- | ----- | ------ |
| `configuration/template.bicep` | Create infrastructure for configuration with App Configuration | [README.md](./configuration/README.md) |
| `functions/template.bicep` | Create infrastructure for an application running with Azure Functions, Storage, CDN, Service Bus, Application Insights, Key Vault | [README.md](./functions/README.md) |
| `functions/local-dependencies.bicep` | Create infrastructure for a local application using Storage, CDN, Service Bus and Key Vault | [README.md](./functions/README.md) |
| `functions/api-registration.bicep` | Register an application as an API Management backend | [README.md](./functions/README.md) |
| `gateway/template.bicep` | Create infrastructure for requests gateway with API Management | [README.md](./gateway/README.md) |
| `identity/template.bicep` | Create infrastructure for identity with AAD B2C | [README.md](./identity/README.md) |
| `management-group/template.bicep` | Deploy a management group | [README.md](./management-group/README.md) |
| `monitoring/template.bicep` | Create infrastructure for monitoring with Log Analytics Workspace | [README.md](./monitoring/README.md) |
| `static-web-apps/template.bicep` | Create infrastructure for an application running with Azure Static Web Apps | [README.md](./static-web-apps/README.md) |
| `web/template.bicep` | Create infrastructure for an application running with App Service, Application Insights, Key Vault | [README.md](./functions/README.md) |

*Note that all templates must start with the prefix `amilochau/azure-templates/`*

### Run manually

These commands can help you run the Bicep templates manually, thanks to `azure cli`:

- `az bicep build --file $templateFile`: builds a Bicep template into ARM template
- `az group create --name $resourceGroupName --location $location`: creates or updates an Azure resource group
- `az deployment group create --resource-group $resourceGroupName --template-file $templateFile --parameters $parametersFile --confirm-with-what-if`: creates a new infrastructure deployment into Azure, after an interactive 'what if' check
- `az deployment group what-if --resource-group $resourceGroupName --template-file $templateFile --parameters $parametersFile`: executes a deployment What-If operation at resource group scope

--- 

## Contribute

Feel free to push your code if you agree with publishing under the [MIT license](./LICENSE).
