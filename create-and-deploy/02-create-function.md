# Create the Azure Function Locally

Install Azure Functions Core Tools, Azure CLI, and .NetCore SDK

Windows Installation - Chocolatey

```terminal
choco install azure-functions-core-tools-3 -y
choco install azure-cli -y
choco install dotnetcore-sdk -y
```

macOS Installation - Homebrew

```terminal
brew update
brew tap azure/functions
brew install azure-functions-core-tools@3
brew install azure-cli
brew install --cask dotnet-sdk
```

Create the function

```terminal
cd repos
mkdir Serverless-LAPS
cd Serverless-LAPS
mkdir function
cd function
mkdir src
mkdir tst
cd src

func init fn-slaps-mk --powershell

cd fn-slaps-mk

func new --name Set-KVSecret --template "HTTP Trigger" --authlevel "function"
```
