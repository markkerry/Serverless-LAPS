rgName="rg-serverless-laps"
location="westeurope"
saName="saslaps4857392"
funcName="fn-slaps-mk"
kvName="kv-slaps-mk"

# create the resource group
az group create --name $rgName --location $location

# check storage account name is available first
az storage account check-name --name $saName

# create the storage account
az storage account create --name $saName \
    --resource-group $rgName \
    --location $location \
    --sku Standard_LRS \
    --kind Storagev2 \
    --access-tier Hot

# create the function app
az functionapp create --name $funcName \
    --resource-group $rgName \
    --consumption-plan-location $location \
    --storage-account $saName \
    --assign-identity [system] \
    --runtime powershell \
    --os-type Windows \
    --functions-version 3

# list the function app
az functionapp list --out table

# create Key Vault
az keyvault create --name $kvName \
    --resource-group $rgName \
    --location $location

# get the function app managed identity
spID=$(az resource list -n $funcName --query [*].identity.principalId --out tsv)

# assign managed identity to the key vault access policy
az keyvault set-policy --name $kvName \
    --secret-permissions create \
    --spn $spID