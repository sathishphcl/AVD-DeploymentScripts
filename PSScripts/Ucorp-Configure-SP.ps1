# to connect to SharePoint Online and you must grant permission to this PnP Management Shell application if you want to connect with user name and password
# Install-Module -Name PnP.PowerShell
Register-PnPManagementShellAccess

Connect-ExchangeOnline
$restrictedGroup = New-DistributionGroup -Name "Sendmail" -Type "Security" -Members @("<mailadres>")
Set-DistributionGroup -Identity $restrictedGroup.Identity -HiddenFromAddressListsEnabled $true

$params = @{
    AccessRight        = "RestrictAccess"
    AppId              = "<AppId>"
    PolicyScopeGroupId = $restrictedGroup.PrimarySmtpAddress
    Description        = "Restrict access to app allowed to send email using the Graph SendMail API"
}

New-ApplicationAccessPolicy @params

# Set read permissions for reporting account in SharePoint
$Creds = Get-Credential

# Parameters
$UserAccount = "<UserAccount>"
$PermissionLevel = "Reader"
$ListName ="Documents"
 
# Connect to PnP Online
Connect-ExchangeOnline  -Credential $Creds
Connect-MicrosoftTeams  -Credential $Creds

$groups = Get-EXORecipient -RecipientTypeDetails GroupMailbox -Properties WhenCreated

foreach($group in $groups){
    if(Get-Team -MailNickName $group.Alias){
        $Site = "https://dictu.sharepoint.com/sites/" + $group.Alias
        Connect-PnPOnline -Url $Site -Credentials $Creds

        # Permissions on site level
        Set-PnPWebPermission -User $UserAccount -AddRole $PermissionLevel

        # Break Permission Inheritance of the List
        Set-PnPList -Identity $ListName -BreakRoleInheritance -CopyRoleAssignments
 
        # Grant permission on List to User
        Set-PnPListPermission -Identity $ListName -AddRole "Read" -User $UserAccount
    }
}