<#PSScriptInfo
.VERSION 1.0
.AUTHOR Ivo Uenk
.RELEASENOTES

#>
<#
.SYNOPSIS
  Monitoring available free space on Azure File Share(s)
.DESCRIPTION
  This will iterate through the storage accounts and checks available space on Azure File Share(s)
.NOTES
  Version:        1.0
  Author:         Ivo Uenk
  Creation Date:  2021-10-11
  Purpose/Change: Monitoring available storage on Azure File Share(s)
#>

# Variables
$MinimumFreeGB = '20'
$creds = Get-AutomationPSCredential -Name "ucorp-mail-user"

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

$Subscriptions = Get-AzSubscription  | Where-Object { $_.State -eq 'Enabled' } | Sort-Object -Unique -Property Id
$fileShares = foreach ($Sub in $Subscriptions) {
    $null = $sub | Set-AzContext
    Get-AzStorageAccount | where-object { $_.PrimaryEndpoints.file } | ForEach-Object {
        $usage = (Get-AzMetric -ResourceId "$($_.id)/fileServices/default" -MetricName "FileCapacity" -AggregationType "Average").data.average
        $Quota = ($_ | Get-AzStorageShare).Quota | select-object -last 1
        [PSCustomObject]@{
            Name              = $_.StorageAccountName
            Sub               = $sub.Name
            ResourceGroupName = $_.StorageAccountName
            PrimaryLocation   = $_.PrimaryLocation
            'Quota GB'        = [int64]$Quota
            'usage GB'        = [math]::round($usage / 1024 / 1024 / 1024)
        }
    }
 
}

$QuotaReached = $fileShares | Where-Object { $_.'quota GB' - $_.'usage GB' -lt $MinimumFreeGB -and $_.'Quota gb' -ne 0 }

# optional mail configuration
$mailConfig = @{
    SMTPServer = "smtp.office365.com"
    SMTPPort = "587"
    Sender = "automation@ucorp.nl"
    Recipients = @("mail@udirection.com", "mail@ivouenk.nl")
    Header = "Storage quota reached"
}

# Mail message template
$mailTemplate = @"
  <html>
  <body>
    <h1>Attention: Check available free space on Azure File Share(s)!</h1>
    <br>
    Please make sure to create available free space on the Azure File Share(s)!
    <br>
    <br>
    <b>Storage Account:</b> STORAGE_ACCOUNT
    <br>
    <b>Subscription:</b> SUBSCRIPTION
    <br>
    <b>Quota GB:</b> QUOTA_GB
    <br>
    <b>Usage GB:</b> USAGE_GB
    <br>
    <b>Help URL: <a href="https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-create-file-share?tabs=azure-portal">Microsoft Docs</a><br>
    <br>
    <br/>
  </body>
</html>
"@

$bodyTemplate = $mailTemplate
$bodyTemplate = $bodyTemplate.Replace("STORAGE_ACCOUNT", $QuotaReached.Name)
$bodyTemplate = $bodyTemplate.Replace("SUBSCRIPTION", $QuotaReached.Sub)
$bodyTemplate = $bodyTemplate.Replace("QUOTA_GB", $QuotaReached.'Quota GB')
$bodyTemplate = $bodyTemplate.Replace("USAGE_GB", $QuotaReached.'usage GB')

if (!$QuotaReached) {
    Write-Output 'Healthy'
}
else {
    Write-Output "Unhealthy. Please check diagnostic data"
    Send-MailMessage -UseSsl -From $mailConfig.Sender -To $mailConfig.Recipients -SmtpServer $mailConfig.SMTPServer -Port $mailConfig.SMTPPort -Subject $mailConfig.Header -Body $bodyTemplate -Credential $creds -BodyAsHtml
}