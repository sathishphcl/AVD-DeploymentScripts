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