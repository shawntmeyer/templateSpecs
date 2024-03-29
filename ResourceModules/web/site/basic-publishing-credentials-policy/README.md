# Web Site Basic Publishing Credentials Policies `[Microsoft.Web/sites/basicPublishingCredentialsPolicies]`

This module deploys a Web Site Basic Publishing Credentials Policy.

## Navigation

- [Resource Types](#Resource-Types)
- [Parameters](#Parameters)
- [Outputs](#Outputs)
- [Cross-referenced modules](#Cross-referenced-modules)

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Web/sites/basicPublishingCredentialsPolicies` | [2022-09-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Web/sites) |

## Parameters

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`name`](#parameter-name) | string | The name of the resource. |

**Conditional parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`webAppName`](#parameter-webappname) | string | The name of the parent web site. Required if the template is used in a standalone deployment. |

**Optional parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`enableDefaultTelemetry`](#parameter-enabledefaulttelemetry) | bool | Enable telemetry via a Globally Unique Identifier (GUID). |
| [`location`](#parameter-location) | string | Location for all Resources. |

### Parameter: `enableDefaultTelemetry`

Enable telemetry via a Globally Unique Identifier (GUID).
- Required: No
- Type: bool
- Default: `True`

### Parameter: `location`

Location for all Resources.
- Required: No
- Type: string
- Default: `[resourceGroup().location]`

### Parameter: `name`

The name of the resource.
- Required: Yes
- Type: string
- Allowed: `[ftp, scm]`

### Parameter: `webAppName`

The name of the parent web site. Required if the template is used in a standalone deployment.
- Required: Yes
- Type: string


## Outputs

| Output | Type | Description |
| :-- | :-- | :-- |
| `location` | string | The location the resource was deployed into. |
| `name` | string | The name of the basic publishing credential policy. |
| `resourceGroupName` | string | The name of the resource group the basic publishing credential policy was deployed into. |
| `resourceId` | string | The resource ID of the basic publishing credential policy. |

## Cross-referenced modules

_None_
