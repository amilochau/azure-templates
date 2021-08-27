[//]: # (Format this CHANGELOG.md with these titles:)
[//]: # (Breaking changes)
[//]: # (New features)
[//]: # (Bug fixes)
[//]: # (Minor changes)

## Breaking changes

Parameters for the `functions` template have been moved:

- `useApplicationInsights` is removed, you should now define the `monitoring` parameter:

```json
"monitoring": {
  "value": {
    "enableApplicationInsights": true,
    "disableLocalAuth": true
  }
}
```

## New features

- Support AAD authentication for Application Insights
