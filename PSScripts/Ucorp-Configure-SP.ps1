$AppID = "bca8f74e-7320-4bde-a6ec-fb2712e439db"
$ExchangeOnlineObjectID = (Get-AzureADServicePrincipal -Filter " AppId eq '00000002-0000-0ff1-ce00-000000000000'").ObjectID
$ExchangeRightsID = "dc50a0fb-09a3-484d-be87-e023b12c6440"
$ServicePrincipalID = (Get-AzureADServicePrincipal -Filter "AppId eq '$AppID'").ObjectId 
New-AzureAdServiceAppRoleAssignment -ObjectId $ServicePrincipalID -PrincipalId $ServicePrincipalID -ResourceId $ExchangeOnlineObjectID -Id $ExchangeRightsID