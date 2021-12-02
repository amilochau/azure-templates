[//]: # (Format this CHANGELOG.md with these titles:)
[//]: # (Breaking changes)
[//]: # (New features)
[//]: # (Bug fixes)
[//]: # (Minor changes)

## New features

- Add the Azure region in the Functions environment variables
- Add the `management-group/template.bicep` template to deploy management group
- Support more built-in roles for RBAC attribution
- Improve storage recoverability for `Production` environment

## Bug fixes

- Avoid creating useless app settings in Functions application
- Fix infinine-loading graph in Functions dashboard

## Minor changes

- HTTP is now removed from CDN, HTTPS remains enabled
