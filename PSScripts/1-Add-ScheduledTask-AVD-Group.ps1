# Create script
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

# Get username and password
$cred = Get-Credential -Message "Enter credentials"
$username = $cred.username
$password = $cred.getnetworkcredential().password

# Parameters for the scheduled task
$taskFolder = 'Ucorp'
$taskName = 'Ucorp-AVD-Add-Hosts-To-Group'
$scriptPath = "\\ucorp.local\SYSVOL\ucorp.local\scripts\Ucorp-AVD-Add-Host-Group.ps1"

$A = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-executionpolicy bypass -noprofile -file $scriptPath" 
$T = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 10)

$exists = Get-ScheduledTask | Where-Object {$_.TaskName -like $taskname}
If($exists) {Unregister-ScheduledTask -TaskName $taskname -Confirm}
Register-ScheduledTask -TaskName "$TaskFolder\$TaskName" -Action $A -Trigger $T -RunLevel Highest -User $username -Password $password -ErrorAction Stop
$cred = ""