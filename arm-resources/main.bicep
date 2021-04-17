// Set the target subscription
targetScope = 'subscription'

// as this is targeted to a subscript we have to create a resource group
resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'ServerlessLAPS'
  location: 'West Europe'
}

// storage account for the KeyVault
module stgMod './storage.bicep' = {
  name: 'storageDeploy' // name for the nested deployment
  scope: resourceGroup(rg.name)
  params: {
    namePrefix: 'SLAPS'
  }
}

// Keyvault module

// Function app module