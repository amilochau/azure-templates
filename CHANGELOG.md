[//]: # (Format this CHANGELOG.md with these titles:)
[//]: # (Breaking changes)
[//]: # (New features)
[//]: # (Bug fixes)
[//]: # (Minor changes)

## Breaking changes

- Parameters for the `functions` template have been moved:
  - Application Insights now requires a Log Analytics workspace
  - `useApplicationInsights` is removed, you should now define the `monitoring` parameter:

  ```json
  "monitoring": {
    "value": {
      "enableApplicationInsights": true,
      "disableLocalAuth": true,
      "dailyCap": "1",
      "workspaceName": "",
      "workspaceResourceGroup": ""
    }
  }
  ```

- The previous parameter `organizationPrefix` is now renamed `organizationName`
- The `app-config` template now uses the following required parameters, instead of the old `appConfigurationName` parameter:
  - `organizationName`
  - `applicationName`
  - `environmentName`
  - `hostName`
- Naming convention has been adapted; here is the new resource convention: `{org}-{app}-{host}-{resourceType}`

## New features

- Application Insights:
  - Support AAD authentication
  - Support a daily cap for data ingestion
  - Support workspace reference
- Log Analytics Workspace:
  - Introduce a new template for monitoring resources (see [here](monitoring/README.md))
