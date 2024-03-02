param storageAccountId string = '/subscriptions/6dc4ed51-16b9-4494-a406-4fb7a8330d95/resourceGroups/rg-function-apps-use/providers/Microsoft.Storage/storageAccounts/safuncappszruse'

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: last(split(storageAccountId, '/'))
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2019-06-01' = {
  name: '${storageAccount.name}/default'
}

resource share 'Microsoft.Storage/storageAccounts/fileServices/shares@2019-06-01' = {
  name: 'share1'
  parent: fileService
  properties: {
    enabledProtocols: 'SMB'
    shareQuota: 5120
  }
}

output storageAccountName string = storageAccount.name
