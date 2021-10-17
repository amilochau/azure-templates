# Readme - functions

## Introduction

`amilochau/azure-templates/functions/template.bicep` is a Bicep template developed to manage infrastructure for an application running with Azure Functions, Storage, CDN, Service Bus, Application Insights, Key Vault.

`amilochau/azure-templates/functions/local-dependencies.bicep` is a Bicep template developed to manage infrastructure for a local application using Storage, CDN, Service Bus, Key Vault.

---

## Usage

Use this Bicep template if you want to deploy infrastructure for an Azure Functions application. This template works well with applications that reference `Milochau.Core.Functions` framework.

You can safely use this template in an IaC automated process, such as a GitHub workflow.

### Template parameters

The following template parameters files are proposed as examples:

| Parameters file | Bicep template | Description |
| --------------- | -------------- | ----------- |
| [`template.params.json`](./template.params.json) | [`template.bicep`](./template.bicep) | Full example |
| [`local-dependencies.params.json`](./local-dependencies.params.json) | [`local-dependencies.bicep`](./local-dependencies.bicep) | Full example |
| [`api-registration.params.json`](./api-registration.params.json) | [`api-registration.bicep`](./api-registration.bicep) | Full example |
