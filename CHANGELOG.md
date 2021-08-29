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

## New features

- Application Insights:
  - Support AAD authentication
  - Support a daily cap for data ingestion
  - Support workspace reference
- Log Analytics Workspace:
  - Introduce a new template for monitoring resources (see [here](monitoring/README.md))
- Add tags (`organization`, `application`, `environment`, `host`) on each resource
- Improve optional support for configuration, monitoring, secrets, storage and messaging features for `functions`
- The `functions` template now supportes `dotnet-isolated` worker runtime
- New templates are proposed:
  - `configuration` let you deploy an App Configuration resource
  - `monitoring` let you deploy a Log Analytics Workspace
  - `gateway` let you deploy an API Management
