<#
.Synopsis
    Customization script for Azure Image Builder
.DESCRIPTION
    Customization script for Azure Image Builder - Language Configuration
.NOTES
    Author: Ivo Uenk
    Version: 1.0
#>

$path = "C:\AIB"
mkdir $path

# Creating logoutput and filenames
$LogFile = $path + "\" + "Language-Configuration-" + (Get-Date -UFormat "%d-%m-%Y") + ".log"

Function Write-Log
{
	param (
        [Parameter(Mandatory=$True)]
        [array]$LogOutput,
        [Parameter(Mandatory=$True)]
        [string]$Path
	)
	$currentDate = (Get-Date -UFormat "%d-%m-%Y")
	$currentTime = (Get-Date -UFormat "%T")
	$logOutput = $logOutput -join (" ")
	"[$currentDate $currentTime] $logOutput" | Out-File $Path -Append
}

$lp_root_folder = "$path\Language" #Root folder where the copied sourcefiles are
$LanguageUrl = 'https://ucorpavdstd.blob.core.windows.net/ucorpavdrepo/Language-Files.zip?sp=r&st=2021-10-06T13:34:23Z&se=2023-10-06T21:34:23Z&spr=https&sv=2020-08-04&sr=b&sig=YZ20T5NN8uF4xCD6aJQmyaMQwRNuA6FdU%2BChPDsf5sY%3D'
$architecture = "x64" #Architecture of cab files
$systemlocale = "nl-NL" #System local when script finishes
$Languagefiles = "Language-Files.zip"

mkdir $lp_root_folder -ErrorAction SilentlyContinue
Invoke-WebRequest $LanguageUrl -OutFile $lp_root_folder\$Languagefiles
Expand-Archive $lp_root_folder\$Languagefiles -DestinationPath $lp_root_folder
Write-Log -LogOutput ("Downloading en extracting Language Files") -Path $LogFile

# Disable Language Pack Cleanup
Disable-ScheduledTask -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -TaskName "Pre-staged app cleanup"

# Start installation of language pack on Win10 2004 and higher
#foreach ($language in Get-ChildItem -Path "$lp_root_folder\LXP") {
    # Check if files exist

 #   $appxfile = $lp_root_folder + "\LXP\" + $language.Name + "\LanguageExperiencePack." + $language.Name + ".Neutral.appx"
 #   $licensefile = $lp_root_folder + "\LXP\" + $language.Name + "\License.xml"
 #   $cabfile = $lp_root_folder + "\LangPack\Microsoft-Windows-Client-Language-Pack_" + $architecture + "_" + $language.Name + ".cab"
   
 #   if (!(Test-Path $appxfile)) {
 #       Write-Log -LogOutput ("$language file missing: $appxfile") -Path $LogFile
 #       Write-Log -LogOutput ("Skipping installation of $language") -Path $LogFile
 #   } elseif (!(Test-Path $licensefile)) {
 #       Write-Log -LogOutput ("$language.file missing: $licensefile") -Path $LogFile
 #       Write-Log -LogOutput ("Skipping installation of $language") -Path $LogFile
 #   } elseif (!(Test-Path $cabfile)) {
 #       Write-Log -LogOutput ("$language file missing: $cabfile") -Path $LogFile
 #       Write-Log -LogOutput ("Skipping installation of $language") -Path $LogFile
 #   } else {
 #       Write-Log -LogOutput ("$language installing $cabfile") -Path $LogFile
 #       Add-WindowsPackage -Online -PackagePath $cabfile

#        Write-Log -LogOutput ("$language installing $appxfile") -Path $LogFile
#        Add-AppProvisionedPackage -Online -PackagePath $appxfile -LicensePath $licensefile
#     }
#}

# Set preferred UI language
#try {
#    New-ItemProperty -ErrorAction Stop -Path "HKLM:\SYSTEM\CurrentControlSet\Control\MUI\Settings" -Name "PreferredUILanguages" -Value $systemlocale -PropertyType MultiString -Force
#    if ((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\MUI\Settings").PSObject.Properties.Name -contains "PreferredUILanguages") {
#        Write-Log -LogOutput ("Added time zone redirection registry key") -Path $LogFile
#    }
#    else {
#        Write-Log -LogOutput ("Error locating the Teams registry key") -Path $LogFile
#    }
#}
#catch {
#    $ErrorMessage = $_.Exception.message
#    Write-Log -LogOutput ("Error adding teams registry KEY: $ErrorMessage") -Path $LogFile
#}

# Update installed Inbox Store Apps added in this step because language is changed to nl-NL
#$lp_root_folder = "$path\Language"
#foreach ($App in (Get-AppxProvisionedPackage -Online)) {
#	$AppPath = $lp_root_folder + "\APP\" + $App.DisplayName + '_' + $App.PublisherId
#	Write-Log -LogOutput ("Handling $AppPath") -Path $LogFile
#	$licFile = Get-Item $AppPath*.xml
#	if ($licFile.Count) {
#		$lic = $true
#		$licFilePath = $licFile.FullName
#	} else {
#		$lic = $false
#	}
#	$appxFile = Get-Item $AppPath*.appx*
#	if ($appxFile.Count) {
#		$appxFilePath = $appxFile.FullName
#		if ($lic) {
#			Add-AppxProvisionedPackage -Online -PackagePath $appxFilePath -LicensePath $licFilePath 
#		} else {
#			Add-AppxProvisionedPackage -Online -PackagePath $appxFilePath -skiplicense
#		}
#	}
#}

# Configure language settings for Current user > Welcome screen > New accounts
#Write-Log -LogOutput ("$systemlocale - Setting language Current user > Welcome screen > New accounts") -Path $LogFile
#$DefaultHKEY = "HKU\DEFAULT_USER"
#$DefaultRegPath = "C:\Users\Default\NTUSER.DAT"

#Set-Culture -CultureInfo $systemlocale
#Set-WinSystemLocale -SystemLocale $systemlocale
#Set-WinHomeLocation -GeoId 176
#Set-WinUserLanguageList $systemlocale -Force
#Set-WinUILanguageOverride $systemlocale
#reg load $DefaultHKEY $DefaultRegPath
#reg import "$lp_root_folder\nl-nl-default.reg"
#reg unload $DefaultHKEY
#reg import "$lp_root_folder\nl-nl-welkom.reg"

#Set-TimeZone -Id "W. Europe Standard Time"