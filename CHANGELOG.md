[//]: # (Format this CHANGELOG.md with these titles:)
[//]: # (Breaking changes)
[//]: # (New features)
[//]: # (Bug fixes)
[//]: # (Minor changes)

## New features

- The `gateway` template now deploys global policies for APIs (.NET Core headers are removed)
- The `gateway` template now deploys a dedicated Key Vault to store secret named values for API Management

## Bug fixes

- The `gateway` template do not create a new named value for loggers at each deployment anymore
