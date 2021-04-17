<#
.SYNOPSIS 
    The local run.ps1 Azure Function for testing.    
.DESCRIPTION 
    After creating the local Azure function using the core-tools cli,
    this script can be used as the run.ps1 file for testing.
.NOTES
    FileName:   Test-Run.ps1
    Author:     Mark Kerry
#>

using namespace System.Net

param(
    [Parameter(Mandatory = $true)]
    $Request
)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Function to generate a random password
function New-Password {
    $alphabets = 'a,b,c,d,e,f,g,h,i,j,k,m,n,p,q,r,t,u,v,w,x,y,z'
    $numbers = 2..9
    $specialCharacters = '@,#,$,%,&,*,?,+'
    $array = @()
    $array += $alphabets.Split(',') | Get-Random -Count 8
    $array[0] = $array[0].ToUpper()
    $array[-1] = $array[-1].ToUpper()
    $array += $numbers | Get-Random -Count 5
    $array += $specialCharacters.Split(',') | Get-Random -Count 2
    ($array | Get-Random -Count $array.Count) -join ""
}

# Generate a random password
$password = New-Password

# Return the password in the response
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    Body = $password
})