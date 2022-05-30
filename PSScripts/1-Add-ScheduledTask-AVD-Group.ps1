# Get username and password
$cred = Get-Credential -Message "Enter credentials"
$username = $cred.username
$password = $cred.getnetworkcredential().password

# Parameters for the scheduled task
$taskFolder = 'Ucorp'
$taskName = 'Ucorp-AVD-Add-Hosts-To-Group'
$scriptPath = "\\ucorp.local\SYSVOL\ucorp.local\scripts\AVD-Add-Host-Group.ps1"

$A = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-executionpolicy bypass -noprofile -file $scriptPath" 
$T = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 10)

$exists = Get-ScheduledTask | Where-Object {$_.TaskName -like $taskname}
If($exists) {Unregister-ScheduledTask -TaskName $taskname -Confirm}
Register-ScheduledTask -TaskName "$TaskFolder\$TaskName" -Action $A -Trigger $T -RunLevel Highest -User $username -Password $password -ErrorAction Stop
$cred = ""

