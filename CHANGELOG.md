[//]: # (Format this CHANGELOG.md with these titles:)
[//]: # (Breaking changes)
[//]: # (New features)
[//]: # (Bug fixes)
[//]: # (Minor changes)

## Breaking changes

- All templates:
  - The global parameter `environmentName` is now removed; environment name is computed from the `hostName` global parameter
  - The new parameter `pricingPlan` let you define the configuration set you want to use for SKUs and billing limits
  - Most of the complex `object`-type parameters have been replaced by flat, validable parameters; please refer to each template to see the new parameters
  - Most of global object references, such as Log Analytics workspace, App Configuration and API Management, have been removed; the templates now use naming conventions to find global resources
- `functions` template:
  - Drops support for local conditional deployment from the `functions/template.bicep` template
  - Drops support for `dotnet` worker type, drops support for `DOTNETCORE|3.1` and `DOTNET|6.0` framework versions

## New features

- `gateway` template:
  - Now deploys global policies for APIs (.NET Core headers are removed)
  - Now deploys a dedicated Key Vault to store secret named values for API Management
  - Now deploys products, from the new `api.products` arrray property
- `functions` template:
  - Now deploys an API Management backend, as defined from then new `api` object property, with the default Functions host key
  - Now deploys an API Management API, as defined from then new `api` object property

## Bug fixes

- The `gateway` template do not create a new named value for loggers at each deployment anymore
- The `configuration` template now works with defined referential
