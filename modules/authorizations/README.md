# Authorizations

Authorizations let other templates add build-in roles to resources.

See [this page](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)

Or use command:
`az role definition list --name 'App Configuration Data Reader' --query [].name -o=tsv`