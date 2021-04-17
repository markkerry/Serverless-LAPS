<#
.SYNOPSIS 
    Test the local Function.    
.DESCRIPTION 
    After creating the local Azure function using the core-tools cli,
    this script can be used to test it.
.NOTES
    FileName:   Test-LocalFunction.ps1
    Author:     Mark Kerry
#>

# Define the userName for the Local Administrator
$userName = "Administrator"

# Azure Function Request Body
$body = @"
{
    "keyName": "$env:COMPUTERNAME",
    "contentType": "Local Administrator Credentials",
    "tags": {
        "Username": "$userName"
    }
}
"@

# URI of the local function
$uri = "http://localhost:7071/api/Set-KVSecret"

# Trigger Azure Function.
try {
    Invoke-RestMethod -Uri $uri -Method POST -Body $body -ContentType 'application/json' -ErrorAction Stop
}
catch {
    Write-Host "$(Get-Date -format g): Failed to submit Local Administrator configuration. StatusCode: $($_.Exception.Response.StatusCode.value__). StatusDescription: $($_.Exception.Response.StatusDescription)"
}