<#
.Synopsis
    Customization script for Azure Image Builder
.DESCRIPTION
    Customization script for Azure Image Builder - Baseline Configuration
.NOTES
    Author: Ivo Uenk
    Version: 1.0
#>

# Creating logoutput and filenames
$path = "C:\AIB"
$LogFile = $path + "\" + "Baseline-Configuration-" + (Get-Date -UFormat "%d-%m-%Y") + ".log"

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

# Disable Store auto update
Schtasks /Change /Tn "\Microsoft\Windows\WindowsUpdate\Scheduled Start" /Disable

# region Time Zone Redirection
$Name = "fEnableTimeZoneRedirection"
$value = "1"

try {
    New-ItemProperty -ErrorAction Stop -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name $name -Value $value -PropertyType DWORD -Force
    if ((Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services").PSObject.Properties.Name -contains $name) {
        Write-Log -LogOutput ("Added time zone redirection registry key") -Path $LogFile
    }
    else {
        Write-Log -LogOutput ("Error locating the Teams registry key") -Path $LogFile
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    Write-Log -LogOutput ("Error adding teams registry KEY: $ErrorMessage") -Path $LogFile
}

# Install Microsoft 365 Apps with customization
Write-Log -LogOutput ("Installing Microsoft 365 Apps with customization") -Path $LogFile
Invoke-WebRequest -Uri 'https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=languagepack&language=nl-nl&platform=x64&source=O16LAP&version=O16GA' -OutFile 'C:\AIB\OfficeSetup.exe'
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/iuenk/AVD/main/AIB/OfficeConfiguration.xml' -OutFile 'C:\AIB\OfficeConfiguration.xml'

Invoke-Expression -command 'C:\AIB\OfficeSetup.exe /configure C:\AIB\OfficeConfiguration.xml'
Start-Sleep -Seconds 600

# Set Wallpaper
#Write-Log -LogOutput ("Set Wallpaper") -Path $LogFile
#$WallpaperUrl = 'https://github.com/iuenk/AVD/raw/main/AIB/Ucorp-Wallpaper.jpg'
#$WallpaperLocation = 'C:\Windows\Web\Wallpaper\Ucorp-Wallpaper.jpg'
#Invoke-WebRequest -Uri $WallpaperUrl -OutFile $WallpaperLocation

# Add MSIX app attach certificate
Write-Log -LogOutput ("Set MSIX app attach certificate") -Path $LogFile
Invoke-WebRequest -Uri 'https://github.com/iuenk/AVD/raw/main/AIB/Ucorp-MSIX-20092021.pfx' -OutFile "$path\Ucorp-MSIX-20092021.pfx"
Import-PfxCertificate -FilePath "$path\Ucorp-MSIX-20092021.pfx" -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople' -Password (ConvertTo-SecureString -String 'Welkom01!' -AsPlainText -Force) -Exportable

# Turn off Teams startup for HKLM will also be done with User GPO
Write-Log -LogOutput ("Remove Teams from startup apps") -Path $LogFile
$Key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32"
$CustomInput = "11,00,00,00,c0,bb,ab,a4,9a,66,d7,01"
$hexified = $CustomInput.Split(',') | ForEach-Object { "0x$_"}
$AttrName = "Teams"
New-Item -Path $Key -Force
New-ItemProperty -Path $Key -Name $AttrName -Value ([byte[]]$hexified) -verbose -ErrorAction 'Stop'

# Remove data but keep logging
$var="log"
$array= @(get-childitem $path -exclude *.$var -name)
for ($i=0; $i -lt $array.length; $i++) {
$removepath=join-path -path $path -childpath $array[$i]
remove-item $removepath -Recurse
} 