[//]: # (Format this CHANGELOG.md with these titles:)
[//]: # (Breaking changes)
[//]: # (New features)
[//]: # (Bug fixes)
[//]: # (Minor changes)

## Breaking changes

- The `gateway` template now requires a new array property: `api.products`

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
