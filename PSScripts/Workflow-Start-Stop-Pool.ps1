<#PSScriptInfo
.VERSION 1.0
.AUTHOR Ivo Uenk
.RELEASENOTES

#>
<#
.SYNOPSIS
  Reboots VMs in a HostPool
.DESCRIPTION
  This will iterate through the VMs registered to a host pool and reboot them. 
.NOTES
  Version:        1.0
  Author:         Ivo Uenk
  Creation Date:  2022-05-30
  Purpose/Change: Start or Stop all session hosts in specific host pool.
#>

workflow Ucorp-AVD-Start-Stop-Pool

{
    Param (
    #Script parameters go here
    [Parameter(mandatory = $true)]
    [string]$HostPoolName,

    [Parameter(mandatory = $true)]
    [string]$HostPoolResourceGroupName,
        
    [Parameter(Mandatory=$true)][ValidateSet("Start","Stop")]
    [string]$Action

    )

    $ErrorActionPreference = 'SilentlyContinue'

	# Get the credential from Automation  
	$credential = Get-AutomationPSCredential -Name 'ucorp-avd-credentials'  
	$userName = $credential.UserName  
	$securePassword = $credential.Password

	# Connect to Microsoft services
	$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userName, $securePassword
	Connect-AzAccount -Credential $Creds

    Write-Output "Starting to run Start or Stop VMs in Host Pool $HostPoolName ..."
    $sessionHosts = Get-AzWvdSessionHost -ResourceGroupName $HostPoolResourceGroupName -HostPoolName $HostPoolName
    foreach ($sh in $sessionHosts) {

        $VMName = $sh.Name.Split("/")[1]
        $VMName = $VMName.Split(".")[0]
        
        $Session = $sh.Session
        $Status = $sh.Status
        $UpdateState = $sh.UpdateState
        $UpdateErrorMessage = $sh.UpdateErrorMessage

        Write-output "Session: $Session"
        Write-output "Status: $Status"
        Write-output "UpdateState: $UpdateState"
        Write-output "UpdateErrorMessage: $UpdateErrorMessage"

        if ($action -eq "Stop") {
            Write-Output "Stopping the VM '$VMName'"!
            Stop-AzVM -ResourceGroupName $HostPoolResourceGroupName -Name $VMName
         
        }else{
            Write-Output "Starting the VM '$VMName'"!
            Start-AzVM -ResourceGroupName $HostPoolResourceGroupName -Name $VMName
        }
    }
}