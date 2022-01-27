<#PSScriptInfo
.VERSION 0.1
.AUTHOR Ivo Uenk
.RELEASENOTES

#>
<#
.SYNOPSIS
  Generate a report about SharePoint-Teams usage
.DESCRIPTION
  Generate a report about SharePoint-Teams usage
.NOTES
  Version:        0.1
  Author:         Ivo Uenk
  Creation Date:  2022-01-25
  Purpose/Change: Generate a report about SharePoint-Teams usage

  Install the following modules:
  PnP.PowerShell
  ExchangeOnlineManagement
  MicrosoftTeams
  Microsoft.Online.SharePoint.PowerShell

#>

# Import modules
Import-Module 'ExchangeOnlineManagement'
Import-Module 'Microsoft.Online.SharePoint.PowerShell'
Import-Module 'PnP.PowerShell'
Import-Module 'MicrosoftTeams'

# Variables
$Tenant = "ucorponline"
$ErrorActionPreference = 'SilentlyContinue'       

# Get the credential from Automation  
$credential = Get-AutomationPSCredential -Name 'AutomationCreds'  
$userName = $credential.UserName  
$securePassword = $credential.Password

$psCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userName, $securePassword  

# Connect to Microsoft 365 Services
Connect-SPOService -Url "https://$($Tenant)-admin.sharepoint.com" -Credential $psCredential
Connect-ExchangeOnline -Credential $psCredential
Connect-MicrosoftTeams -Credential $psCredential

$groups = Get-EXORecipient -RecipientTypeDetails GroupMailbox -Properties WhenCreated

$table = $null
$Table = New-Object System.Collections.ArrayList
foreach($group in $groups){
    $Line = New-Object -TypeName psobject
    if(Get-Team -MailNickName $group.Alias){

        # Get M365 group
        Add-Member -InputObject $Line -MemberType NoteProperty -Name "Name" -Value $group.DisplayName
        $s = $group.PrimarySmtpAddress
        Add-Member -InputObject $Line -MemberType NoteProperty -Name "Service" -Value ($s.Substring(0, $s.IndexOf('@')))
        Add-Member -InputObject $Line -MemberType NoteProperty -Name "Email" -Value $group.PrimarySmtpAddress
        Add-Member -InputObject $Line -MemberType NoteProperty -Name "Created" -Value $group.WhenCreated.ToString()
        
        # Get SPO site
        $Sitecheck = "https://$($Tenant).sharepoint.com/sites/" + $group.Alias
        if($null -ne (Get-SPOSite -Limit all | Where-Object Url -eq $Sitecheck)){$Site = Get-SPOSite $Sitecheck | Select-Object *}else{$Site = Get-SPOSite -Limit all | Where-Object Url -like ($Sitecheck + "*") | Select-Object *} $Site.Url
        Add-Member -InputObject $Line -MemberType NoteProperty -Name "Status" -Value $Site.Status
        Add-Member -InputObject $Line -MemberType NoteProperty -Name "Modified" -Value $Site.LastContentModifiedDate.ToString()
        Add-Member -InputObject $Line -MemberType NoteProperty -Name "Usage MB" -Value $Site.StorageUsageCurrent.ToString()
        Add-Member -InputObject $Line -MemberType NoteProperty -Name "Conditional" -Value $site.ConditionalAccessPolicy
        Add-Member -InputObject $Line -MemberType NoteProperty -Name "Sharing" -Value $site.SharingCapability

        # Get SPO files
        $Site = "https://$($Tenant).sharepoint.com/sites/" + $group.Alias
        Connect-PnPOnline -Url $Site -Credential $psCredential

        #Store in variable all the document libraries in the site
        $DocLibrary = Get-PnPList -Identity "Documents"
 
        $files = @()
        foreach ($DocLib in $DocLibrary) {
 
            #Get list of all items in the document library
            $AllItems = Get-PnPListItem -PageSize 1000 -List $DocLib -Fields "ID"

           #Loop through each files/folders in the document library for folder size = 0
            foreach ($Item in $AllItems) {
                if ($Item["FileLeafRef"] -like "*.*") {
 
                    $files += $Item["FileLeafRef"]
                }
            }
        }
        Add-Member -InputObject $Line -MemberType NoteProperty -Name "Files" -Value $files.Count

        # Get Teams settings
        $Team = (Get-Team -DisplayName $group.Alias)
        $TeamOwner = (Get-TeamUser -GroupId $Team.GroupId | Where-Object{$_.Role -eq 'Owner'}).User -join ","
        $TeamUserCount = ((Get-TeamUser -GroupId $Team.GroupId).UserID).Count
        $TeamGuests = (Get-UnifiedGroupLinks -LinkType Members -Identity $group.Alias | Where-Object{$_.Name -match "#EXT#"}).Name
            if ($null -eq $TeamGuests)
            {
                $TeamGuests = "No Guests"
            }
        $ChannelCount = (Get-TeamChannel -GroupId $Team.GroupId).ID.Count

        Add-Member -InputObject $Line -MemberType NoteProperty -Name "Owners" -Value $TeamOwner
        Add-Member -InputObject $Line -MemberType NoteProperty -Name "Users" -Value $TeamUserCount
        Add-Member -InputObject $Line -MemberType NoteProperty -Name "Guests" -Value $TeamGuests
        Add-Member -InputObject $Line -MemberType NoteProperty -Name "Channels" -Value $ChannelCount

        [void]$Table.Add($Line)
    }
}

# Get Date
$ReportDate = (Get-Date).ToString("dd-MM-yyyy")

# HTML Template
$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: White; background-color: #154273;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

$EmailBody = $Table | ConvertTo-Html -Body "<H2>SharePoint Teams Report $($ReportDate)</H2>" -Head $Header

# Mail configuration
$mailConfig = @{
    SMTPServer = "smtp.office365.com"
    SMTPPort = "587"
    Sender = "automation@ucorp.nl"
    Recipients = @("mail@ivouenk.nl")
    Header = "SharePoint-Teams report on: "+$ReportDate
}

Send-MailMessage -UseSsl -From $MailConfig.Sender `
-To $MailConfig.Recipients `
-SmtpServer $MailConfig.Smtpserver `
-Port $MailConfig.SMTPPort `
-Subject $MailConfig.Header `
-Body ($EmailBody | Out-String) -BodyAsHtml -Credential $psCredential

Disconnect-ExchangeOnline
Disconnect-SPOService
Disconnect-MicrosoftTeams
Disconnect-PnPOnline  