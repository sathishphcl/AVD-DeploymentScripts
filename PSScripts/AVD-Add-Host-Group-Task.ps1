$TargetGroup = "SG_AVD_Hosts"
$TargetOU = "OU=AVD,OU=Ucorp,DC=ucorp,DC=local"

$AVDHosts = Get-ADComputer -Filter * | Where-Object {$_.DistinguishedName -like "*$TargetOU*" -and $_.Enabled -eq "True"}

ForEach($AVDHost in $AVDHosts)
{
    $HostName = $AVDHost.Name

    $Membership = Get-ADGroup $TargetGroup | Get-ADGroupMember | Where-Object {$_.Name -eq $HostName}
    if(!$Membership)
    {
    "Adding $HostName to $TargetGroup"
    Get-ADGroup $TargetGroup | Add-ADGroupMember -Members $AVDHost -Verbose
    }
}