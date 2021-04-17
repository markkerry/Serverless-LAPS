param namePrefix string = ''

resource stg 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: '${namePrefix}${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name:'Standard_LRS'
  }
}

output blobEndpoint string = stg.properties.primaryEndpoints.blob