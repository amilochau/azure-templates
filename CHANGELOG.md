[//]: # (Format this CHANGELOG.md with these titles:)
[//]: # (Breaking changes)
[//]: # (New features)
[//]: # (Bug fixes)
[//]: # (Minor changes)

## Breaking changes

- Parameters for the `functions` template have been moved, see [this page](functions/README.md) to learn more
- Parameters for the `app-config` template have been moved, see [this page](functions/README.md) to learn more
- The formerly `app-config` template is now named `configuration`
- The previous parameter `organizationPrefix` is now renamed `organizationName`
- Naming convention has been adapted; here is the new resource convention: `{org}-{app}-{host}-{resourceType}`
- Azure Functions settings for organization, application, environment, host, App Configuration and Key Vault now use the `AZURE_FUNCTIONS_` prefix
- Azure Functions now uses Managed Identity for Service Bus triggers; please use the new `AzureWebJobsServiceBus` reference in the code, instead of the old `ServiceBusConnectionString` (see [this page](https://docs.microsoft.com/en-us/azure/azure-functions/functions-reference#configure-an-identity-based-connection))

## New features

- Application Insights:
  - Support AAD authentication
  - Support a daily cap for data ingestion
  - Support workspace reference
- Log Analytics Workspace:
  - Introduce a new template for monitoring resources (see [here](monitoring/README.md))
- Service Bus:
  - Support Managed Identity connection from Azure Functions
- Add tags (`organization`, `application`, `environment`, `host`) on each resource and on current resource group
- Improve optional support for configuration, monitoring, secrets, storage and messaging features for `functions`
- The `functions` template now supports `dotnet-isolated` worker runtime
- The `functions` template now supports a daily memory time quota
- New templates are proposed:
  - `configuration` let you deploy an App Configuration resource
  - `monitoring` let you deploy a Log Analytics Workspace
  - `gateway` let you deploy an API Management
- Azure Functions now uses Managed Identity for its technical Storage Account
- Add minimum TLS version for website SCM
