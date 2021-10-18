#Connect-AzAccount
$CustomerPrefix = "ucorp"
$tenantID = "<tenantId>"
$subscriptionID = "<subscriptionId>"

# Make connection with tenant
Connect-AzAccount -TenantId $tenantID -SubscriptionId $subscriptionID
          
# Create Service Principal and get credentials
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

# Assign Graph API app registration rights otherwise Get-AzRoleAssignment in 2-Create-AIB-Identity will not work
# It's a bug see info https://github.com/Azure/azure-powershell/issues/13573
# Azure Active Directory Graph -> Directory.Read.All Application
# Microsoft Graph -> Directory.Read.All Application

##################################### NOTICE ##########################################################################
# Copy the output and place it somewhere safe! You cannot get this info later!
Write-Host "You can now add the Azure Resource Manager connecting string and connect the Azure Vault in Azure DevOps, use informatie below"
$jsonresp | ConvertTo-Json