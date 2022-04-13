<#PSScriptInfo
.VERSION 1.0
.AUTHOR Ivo Uenk
.RELEASENOTES

#>
<#
.SYNOPSIS
  Start or stop all hosts in specific HostPool
.DESCRIPTION
  Start or Stop all session hosts in specific HostPool.
.NOTES
  Version:        1.0
  Author:         Ivo Uenk
  Creation Date:  2021-09-13
  Purpose/Change: Start or Stop all session hosts in specific HostPool.
#>

workflow Ucorp-Workflow-Start-Stop-Pool

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

    $connectionName = "AzureRunAsConnection"
    try
    {
        # Get the connection "AzureRunAsConnection "
        $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName       
        "Logging in to Azure..."
        Connect-AzAccount `
            -ServicePrincipal `
            -TenantId $servicePrincipalConnection.TenantId `
            -ApplicationId $servicePrincipalConnection.ApplicationId `
            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
    }
    catch {
        if (!$servicePrincipalConnection)
        {
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        } else{
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }

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