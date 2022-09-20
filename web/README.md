# Readme - web

## Introduction

`amilochau/azure-templates/web/template.bicep` is a Bicep template developed to manage infrastructure for a Docker application running with App Service, Storage, CDN, Service Bus, Application Insights, Key Vault.

---

## Usage

Use this Bicep template if you want to deploy infrastructure for a Web application. This template works well with applications that reference `Milochau.Core.AspNetCore` framework.

You can safely use this template in an IaC automated process, such as a GitHub workflow.

### Template parameters

The following template parameters files are proposed as examples:

| Parameters file | Bicep template | Description |
| --------------- | -------------- | ----------- |
| [`template.params.json`](./template.params.json) | [`template.bicep`](./template.bicep) | Full example |
