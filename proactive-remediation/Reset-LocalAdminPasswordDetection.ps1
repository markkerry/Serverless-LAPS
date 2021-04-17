<#
.SYNOPSIS
    Discovery script for a MEM Proactive Remediation.
.DESCRIPTION
    Checks when the local admin password was last set. 
        - If within 6 months, return complaint
        - If later than 6 months, return non-compliant and remediation will run
        - If local admin account does not exist, return non-compliant and remediation will run
.NOTES
    FileName:   Reset-LocalAdminPasswordDiscovery.ps1
    Author:     Mark Kerry
#>

# Get user account properties
# Enter the name of the local admin account below
$userName = ""
$user = Get-LocalUser -Name $userName -ErrorAction SilentlyContinue
$date = (Get-Date).AddDays(-180)

# Validate compliance
if ($null -ne $user) {
    # account was found
    if ($user.PasswordLastSet -gt $date) {
        # Password was set less than 180 days ago
        Write-Output "Compliant. Password last set $($user.PasswordLastSet)"
        exit 0
    }
    else {
        # Password was set more than 180 days ago
        Write-Output "Non-compliant. Password last set $($user.PasswordLastSet)"
        exit 1
    }
}
else {
    # account was not found
    Write-Output "Non-compliant. Account not found"
    exit 1
}