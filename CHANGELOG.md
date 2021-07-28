[//]: # (Format this CHANGELOG.md with these titles:)
[//]: # (Breaking changes)
[//]: # (New features)
[//]: # (Bug fixes)
[//]: # (Minor changes)

## New features

- The `functions` template now supports multiple containers with RBAC authorizations.

## Breaking changes

The `functions` template introduces many breaking changes in its parameters.

### Migration guide

These parameters have been updated:

- `useServiceBus` is removed; Service Bus Namespace is created if at least one queue is defined in the `serviceBusQueues` parameter
- `useAppConfiguration` is removed; an existing App Configuration is required, as it was planned with the required parameters `appConfigurationName` and `appConfigurationResourceGroup`
- `storageAccounts` is added, as a list of Storage Accounts to create; each storage account can define the sub-properties `number` (*string*), `containers` (*array of strings*), `readOnly` (*bool*), `daysBeforeDeletion` (*int*)
