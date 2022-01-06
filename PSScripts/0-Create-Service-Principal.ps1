#Connect-AzAccount
$CustomerPrefix = "ucorp"
$tenantID = "<tenantId>"
$subscriptionID = "<subscriptionId>"

# Make connection with tenant
Connect-AzAccount -TenantId $tenantID -SubscriptionId $subscriptionID
          
# Create Service Principal and get credentials
##### WARNING secret ID only with Graph API not working anymore with PS #####
$sp = New-AzADServicePrincipal -DisplayName "$CustomerPrefix-avd-sp"
$clientsec = [System.Net.NetworkCredential]::new("", $sp.Secret).Password
$tenantID = (get-aztenant).Id
$jsonresp = 
@{clientId=$sp.ApplicationId 
    clientSecret=$clientsec
    subscriptionId=$subscriptionID
    tenantId=$tenantID
    activeDirectoryEndpointUrl="https://login.microsoftonline.com"
    resourceManagerEndpointUrl="https://management.azure.com/"
    activeDirectoryGraphResourceID="https://graph.windows.net/"
    sqlManagementEdnpointUrl="https://management.core.windows.net:8443/"
    galleryEndpointUrl="https://gallery.azure.com/"
    managementEndpointUrl="https://management.core.windows.net/"}
    $jsonresp | ConvertTo-Json

$spid = (Get-AzADServicePrincipal -DisplayName $SP.DisplayName).Id

New-AzRoleAssignment -ObjectId $spid -RoleDefinitionName "Contributor" -Scope /subscriptions/$subscriptionID
New-AzRoleAssignment -ObjectId $spid -RoleDefinitionName "User Access Administrator" -Scope /subscriptions/$subscriptionID
New-AzRoleAssignment -ObjectId $spid -RoleDefinitionName "Desktop Virtualization Contributor" -Scope /subscriptions/$subscriptionID
New-AzRoleAssignment -ObjectId $spid -RoleDefinitionName "Storage Blob Data Contributor" -Scope /subscriptions/$subscriptionID

##################################### NOTICE ##########################################################################
# Copy the output and place it somewhere safe! You cannot get this info later!
Write-Host "You can now add the Azure Resource Manager connecting string and connect the Azure Vault in Azure DevOps, use informatie below"
$jsonresp | ConvertTo-Json

##################################### NOTICE ##########################################################################

# Assign Graph API app registration rights otherwise Get-AzRoleAssignment in 2-Create-AIB-Identity will not work
# It's a bug see info https://github.com/Azure/azure-powershell/issues/13573
# Azure Active Directory Graph -> Directory.Read.All Application
# Microsoft Graph -> Directory.Read.All Application

# It's not posible to assign the Azure Active Directory Graph from the GUI use code below to add permissions
# You still need to grant permissions after adding them
# A full refresh of the portal is needed before you can see the new permissions
$AppObjectID = "<AppObjectID>" # object id from Service Principal Name
$app = Get-AzureADApplication -ObjectId $AppObjectID
$AADAccess = $app.RequiredResourceAccess | Where-Object {$_.ResourceAppId -eq "00000002-0000-0000-c000-000000000000"}  # "00000002-0000-0000-c000-000000000000" represents AAD Graph API
if($AADAccess -eq $null) {
              $AADAccess = New-Object Microsoft.Open.AzureAD.Model.RequiredResourceAccess
              $AADAccess.ResourceAppId = "00000002-0000-0000-c000-000000000000"
              $Access = New-Object Microsoft.Open.AzureAD.Model.ResourceAccess
              $Access.Type = "Role" # Scope is delgated, Role is application.
              $Access.Id = "5778995a-e1bf-45b8-affa-663a9f3f4d04" # Directory.Read.All
              $AADAccess.ResourceAccess = @()
              $AADAccess.ResourceAccess.Add($Access)
          $app.RequiredResourceAccess.Add($AADAccess)
} else {
              $Access = New-Object Microsoft.Open.AzureAD.Model.ResourceAccess
              $Access.Type = "Role" # Scope is delgated, Role is application.
              $Access.Id = "5778995a-e1bf-45b8-affa-663a9f3f4d04" # Directory.Read.All
              $AADAccess.ResourceAccess.Add($Access)
}
Set-AzureADApplication -ObjectId $AppObjectID -RequiredResourceAccess $app.RequiredResourceAccess