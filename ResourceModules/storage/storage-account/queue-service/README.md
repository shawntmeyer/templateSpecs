# Storage Account Queue Services `[Microsoft.Storage/storageAccounts/queueServices]`

This module deploys a Storage Account Queue Service.

## Navigation

- [Resource Types](#Resource-Types)
- [Parameters](#Parameters)
- [Outputs](#Outputs)
- [Cross-referenced modules](#Cross-referenced-modules)

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Authorization/roleAssignments` | [2022-04-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Authorization/2022-04-01/roleAssignments) |
| `Microsoft.Insights/diagnosticSettings` | [2021-05-01-preview](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Insights/2021-05-01-preview/diagnosticSettings) |
| `Microsoft.Storage/storageAccounts/queueServices` | [2021-09-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Storage/2021-09-01/storageAccounts/queueServices) |
| `Microsoft.Storage/storageAccounts/queueServices/queues` | [2021-09-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Storage/2021-09-01/storageAccounts/queueServices/queues) |

## Parameters

**Conditional parameters**

| Parameter Name | Type | Description |
| :-- | :-- | :-- |
| `storageAccountName` | string | The name of the parent Storage Account. Required if the template is used in a standalone deployment. |

**Optional parameters**

| Parameter Name | Type | Default Value | Allowed Values | Description |
| :-- | :-- | :-- | :-- | :-- |
| `diagnosticEventHubAuthorizationRuleId` | string | `''` |  | Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to. |
| `diagnosticEventHubName` | string | `''` |  | Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category. |
| `diagnosticLogCategoriesToEnable` | array | `[allLogs]` | `['', allLogs, StorageDelete, StorageRead, StorageWrite]` | The name of logs that will be streamed. "allLogs" includes all possible logs for the resource. Set to '' to disable log collection. |
| `diagnosticMetricsToEnable` | array | `[Transaction]` | `[Transaction]` | The name of metrics that will be streamed. |
| `diagnosticSettingsName` | string | `''` |  | The name of the diagnostic setting, if deployed. If left empty, it defaults to "<resourceName>-diagnosticSettings". |
| `diagnosticStorageAccountId` | string | `''` |  | Resource ID of the diagnostic storage account. |
| `diagnosticWorkspaceId` | string | `''` |  | Resource ID of a log analytics workspace. |
| `enableDefaultTelemetry` | bool | `True` |  | Enable telemetry via a Globally Unique Identifier (GUID). |
| `queues` | array | `[]` |  | Queues to create. |


## Outputs

| Output Name | Type | Description |
| :-- | :-- | :-- |
| `name` | string | The name of the deployed file share service. |
| `resourceGroupName` | string | The resource group of the deployed file share service. |
| `resourceId` | string | The resource ID of the deployed file share service. |

## Cross-referenced modules

_None_
