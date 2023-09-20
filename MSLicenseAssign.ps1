<# Script to License Students and Employees in O365
 Created by J. Carlton Bryan
 05/30/2023
 added check for installed modules => 9/19/2023
#>

$MsGraphModule =  Get-Module Microsoft.Graph -ListAvailable
if($null -eq $MsGraphModule)
{
    Write-host "Important: Microsoft graph module is unavailable. It is mandatory to have this module installed in the system to run the script successfully."
    $confirm = Read-Host Are you sure you want to install Microsoft graph module? [Y] Yes [N] No
    if($confirm -match "[yY]")
    {
        Write-host "Installing Microsoft graph module..."
        Install-Module Microsoft.Graph -AllowClobber -Force
        Import-Module Microsoft.Graph.Users, Microsoft.Graph.Users.Actions
        Write-host "Microsoft graph module is installed in the machine successfully" -ForegroundColor Magenta
    }
    else
    {
        Write-host "Exiting. `nNote: Microsoft graph module must be available in your system to run the script" -ForegroundColor Red
        Exit
    }
}
    Connect-MgGraph -scope User.ReadWrite.All, Organization.Read.All  -ErrorAction SilentlyContinue -Errorvariable ConnectionError |Out-Null
    if($ConnectionError -ne $null)
    {
        Write-Host "$ConnectionError" -Foregroundcolor Red
        Exit
    }
$unlicensedUsersJCB = $null
$unlicensedUsersJCB = Get-MgUser -Filter 'assignedLicenses/$count eq 0 and OnPremisesSyncEnabled eq true and accountEnabled eq true' -ConsistencyLevel eventual -CountVariable unlicensedUserCount -All -Select Mail, UserPrincipalName, ID

$license1 = Get-MgSubscribedSku | Where-Object {$_.SkuPartNumber -eq "SKU License Number"}
$license2 = Get-MgSubscribedSku | Where-Object {$_.SkuPartNumber -eq "SKU License Number"}

ForEach ($user in $unlicensedUsersJCB)  # cycle through unlicensed user
    {
    If ($user.Mail)  # Has email - assign License
        {
          if ($user.Mail -match "@student.email") # Student
           {
        Update-MgUser -UserId $user.Id -UsageLocation US
        Set-MgUserLicense -UserId $user.Id -AddLicenses @{SkuId = ($license1.SkuId)} -RemoveLicenses @()
          } # end student section

          if ($user.Mail -match "@employee.email") # Employee
           {
        Update-MgUser -UserId $user.Id -UsageLocation US
        Set-MgUserLicense -UserId $user.Id -AddLicenses @{SkuId = ($license2.SkuId)} -RemoveLicenses @()
          } # end employee section
        } # end if - assign License
    } # end ForEach
