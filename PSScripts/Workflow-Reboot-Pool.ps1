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
  Purpose/Change: Rebooting Session Hosts
#>

workflow Ucorp-AVD-Reboot-Pool

{
    Param (
    #Script parameters go here
    [Parameter(mandatory = $true)]
    [string]$HostPoolName,

    [Parameter(mandatory = $true)]
    [string]$HostPoolResourceGroupName,
        
    [Parameter(mandatory = $true)]
    [boolean]$SkipIfActiveSessions,

    [Parameter(mandatory = $true)]
    [boolean]$OnlyDoIfNeedsAssistance
    )

    $ErrorActionPreference = 'SilentlyContinue'

    # Get the credential from Automation  
	$credential = Get-AutomationPSCredential -Name 'ucorp-avd-credentials'  
	$userName = $credential.UserName  
	$securePassword = $credential.Password
	$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userName, $securePassword

	# Connect to Microsoft services
	Connect-AzAccount -Credential $Creds

    Write-Output "Starting to Enable Boot Diagnostics for VMs in Host Pool $HostPoolName ..."
    if ($OnlyDoIfNeedsAttention) {
        Write-Output "!! Only hosts flagged as 'Needs Assistance' will be rebooted !!"
    }
    if ($SkipIfActiveSessions) {
        Write-Output "!! Only hosts with zero sessions will be rebooted !!"
    }

    $rebooted = 0
    $skippedSessions = 0
    $skippedOK = 0
    $shutdown = 0

    $sessionHosts = Get-AzWvdSessionHost -ResourceGroupName $HostPoolResourceGroupName -HostPoolName $HostPoolName
    foreach ($sh in $sessionHosts) {
        

        # Name is in the format 'host-pool-name/vmname.domainfqdn' so need to split the last part
        $VMName = $sh.Name.Split("/")[1]
        $VMName = $VMName.Split(".")[0]
        
        $Session = $sh.Session
        $Status = $sh.Status
        $UpdateState = $sh.UpdateState
        $UpdateErrorMessage = $sh.UpdateErrorMessage

        Write-output "=== Starting Reboot for VM: $VMName"
        Write-output "Session: $Session"
        Write-output "Status: $Status"
        Write-output "UpdateState: $UpdateState"
        Write-output "UpdateErrorMessage: $UpdateErrorMessage"

        if ($Status -ne "Unavailable") {
            if ($Status -ne "NeedsAssistance" -and $OnlyDoIfNeedsAssistance -eq "True") {
                $skippedOK += 1
                Write-output "!! The VM '$VMName' is not in 'Needs Assistance' state, so will NOT be rebooted. !!"       
            }
            elseif ($Session -gt 0 -and $SkipIfActiveSessions -eq "True") {
                $skippedSessions += 1
                Write-output "!! The VM '$VMName' has $Session session(s), so will NOT be rebooted. !!"       
            }
            else {
                $rebooted += 1
                Restart-AzVM -ResourceGroupName $HostPoolResourceGroupName -Name $VMName
                Write-output "=== Reboot initiated for VM: $VMName"       
            }
        }
        else {
            $shutdown += 1
            Write-output "!! The VM '$VMName' must be started in order to reboot it. !!"       
        }

    }

}