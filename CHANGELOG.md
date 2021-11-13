[//]: # (Format this CHANGELOG.md with these titles:)
[//]: # (Breaking changes)
[//]: # (New features)
[//]: # (Bug fixes)
[//]: # (Minor changes)

## Breaking changes

- The previous `number` parameter for storage accounts in `functions` templates has been renamed; you should now use the `suffix` parameter instead

## New features

- Support `Shared` environment
- Support hyphens in application name where Storage Accounts are deployed
- Add the `static-web-apps/template.bicep` template to create infrastructure for an application running with Azure Static Web Apps

## Bug fixes

- Application name (the `applicationName` template parameter) is now limited to 11 characters, to reflect limits with Key Vault naming limits
- Reduce Bicep linter verbosity on deployment
- Fix authorization on Functions template without extra storage
