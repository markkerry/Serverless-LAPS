<#
.SYNOPSIS 
    Remediation script for a MEM Proactive Remediation.    
.DESCRIPTION 
    This script sets the local Administrator Password if not already set.
    See Infrastructure Documentation
.NOTES
    FileName:   Reset-LocalAdminPasswordDiscovery.ps1
#>

# Create the log file function
function Write-LogEntry {
    param(
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Value,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = "LocalAdminPwd.log"
    )
    # Determine log file location
    $LogFilePath = Join-Path -Path $env:windir -ChildPath "Logs\$($FileName)"

    # Add value to log file
    try {
        Out-File -InputObject $Value -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to append log entry to LocalAdminPwd.log file"
        exit 1
    }
}

$exitCode = 0

# New-LocalUser is only available in a x64 PowerShell process. We need to restart the script as x64 bit first.
if (-not [System.Environment]::Is64BitProcess) {
    # start new PowerShell as x64 bit process, wait for it and gather exit code and standard error output
    $sysNativePowerShell = "$($PSHOME.ToLower().Replace("syswow64", "sysnative"))\powershell.exe"

    $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processStartInfo.FileName = $sysNativePowerShell
    $processStartInfo.Arguments = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $processStartInfo.RedirectStandardError = $true
    $processStartInfo.RedirectStandardOutput = $true
    $processStartInfo.CreateNoWindow = $true
    $processStartInfo.UseShellExecute = $false

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processStartInfo
    $process.Start()

    $exitCode = $process.ExitCode

    $standardError = $process.StandardError.ReadToEnd()
    if ($standardError) {
        Write-Error -Message $standardError 
    }
}
else {
    Write-LogEntry -Value "$(Get-Date -format g): Starting New-LocalAdmin.ps1 script"

    # region Configuration
    # Define the userName for the Local Administrator
    $userName = ""

    # Azure Function Uri (containing "azurewebsites.net") for storing Local Administrator secret in Azure Key Vault
    $uri = ""
    # end region

    # Hide the $Uri (containing "azurewebsites.net") from logs to prevent manipulation of Azure Key Vault
    $intuneManagementExtensionLogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"
    Set-Content -Path $intuneManagementExtensionLogPath -Value (Get-Content -Path $intuneManagementExtensionLogPath | Select-String -Pattern "azurewebsites.net" -notmatch)

    # Azure Function Request Body. Azure Function will strip the keyName and add a secret value. https://docs.microsoft.com/en-us/rest/api/keyvault/setsecret/setsecret
    $body = @"
    {
        "keyName": "$env:COMPUTERNAME",
        "contentType": "Local Administrator Credentials",
        "tags": {
            "Username": "$userName"
        }
    }
"@

    # Use TLS 1.2 connection
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-LogEntry -Value "$(Get-Date -format g): Attempting to retrieve new password"
    # Trigger Azure Function.
    try {
        $password = Invoke-RestMethod -Uri $uri -Method POST -Body $body -ContentType 'application/json' -ErrorAction Stop
    }
    catch {
        Write-LogEntry -Value "$(Get-Date -format g): Failed to submit Local Administrator configuration. StatusCode: $($_.Exception.Response.StatusCode.value__). StatusDescription: $($_.Exception.Response.StatusDescription)"
    }

    if ($null -ne $password) {
        # Convert password to Secure String
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        
        $users = Get-LocalUser

        # Check if the user exists and if so set the password
        if ($users.Name -like $userName) {
            Write-LogEntry -Value "$(Get-Date -format g): Local user exists"
            Write-LogEntry -Value "$(Get-Date -format g): Attempting to change the password"
            try {
                Set-LocalUser -Name $userName -Password $securePassword
            }
            catch {
                Write-LogEntry -Value "$(Get-Date -format g): Failed to change the password"
                $exitCode = -1
                Write-Error $_
            }
        } # if not create the user and set the password
        else {
            Write-LogEntry -Value "$(Get-Date -format g): Local user does not exist"
            Write-LogEntry -Value "$(Get-Date -format g): Attempting to create the user"
            try {
                New-LocalUser -Name $userName -Password $securePassword -PasswordNeverExpires:$true -AccountNeverExpires:$true -ErrorAction Stop
            }
            catch {
                Write-LogEntry -Value "$(Get-Date -format g): Failed to create the user"
                $exitCode = -1
                Write-Error $_
            }
            # Add the new Local User to the Local Administrators group
            Write-LogEntry -Value "$(Get-Date -format g): Attempting to add the user to the Local Administrators Group"
            try {
                Add-LocalGroupMember -SID 'S-1-5-32-544' -Member $userName
                Write-LogEntry -Value "$(Get-Date -format g): Added Local User to the Local Administrators Group"
            }
            catch {
                Write-LogEntry -Value "$(Get-Date -format g): Failed to add the Local User to the Local Administrators Group"
                $exitCode = -1
                Write-Error $_
            }
        }
    }
    else {
        Write-LogEntry -Value "$(Get-Date -format g): Failed to retrieve new password from Azure Function"
        $exitCode = -1
    }
}

Write-LogEntry -Value "$(Get-Date -format g): Finished New-LocalAdmin.ps1 script"
exit $exitCode