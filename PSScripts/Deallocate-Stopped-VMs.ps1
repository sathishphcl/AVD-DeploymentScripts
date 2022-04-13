<#PSScriptInfo
.VERSION 1.0
.AUTHOR Ivo Uenk
.RELEASENOTES

#>
<#
.SYNOPSIS
  Deallocate all stopped VMs
.DESCRIPTION
  Deallocate all stopped VMs
.NOTES
  Version:        1.0
  Author:         Ivo Uenk
  Creation Date:  2022-04-13
  Purpose/Change: Deallocate all stopped VMs

  Install the following modules in Automation Accounts:
  AzureADPreview
  Az
#>

Import-Module 'Az'
Import-Module 'AzureADPreview'

# Get the credential from Automation  
$credential = Get-AutomationPSCredential -Name 'AutomationCreds'  
$userName = $credential.UserName  
$securePassword = $credential.Password

$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.Password = $Password
$PasswordProfile.ForceChangePasswordNextLogin = $true
$psCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userName, $securePassword

Connect-AzureAD -Credential $psCredential
Connect-AzAccount -Credential $psCredential

Get-AzVM | Where-Object {$_.Name -like "Ucorp-AVD-*"} | `
Select-Object Name, ResourceGroupName, @{Name="Status";
    Expression={(Get-AzVM -Name $_.Name -ResourceGroupName $_.ResourceGroupName -status).Statuses[1].displayStatus}} | `
Where-Object {$_.Status -eq "VM stopped"} | `
Stop-AzVM -Force