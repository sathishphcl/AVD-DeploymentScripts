Connect-AzAccount
$AllHostPools = Get-AzResource | Where-Object ResourceType -eq Microsoft.DesktopVirtualization/hostpools
        foreach ($HostPool in $AllHostPools) {
            $HostPoolValidation = Get-AzWVDHostPool -Name $HostPool.Name -ResourceGroupName $HostPool.ResourceGroupName
            if ($HostPoolValidation.HostPoolType -eq "Pooled") {
                if ($HostPoolValidation.StartVMOnConnect -eq $true) {
                    Write-Host "The HostPool "$HostPoolValidation.Name" has the feature already enabled. Continue with the next one"
                }
                else {
                    Update-AzWvdHostPool -Name $HostPool.Name -ResourceGroup $HostPool.ResourceGroupName -StartVMOnConnect:$true
                    Write-Host "Start VM on Connect has been successfully configured for Host Pool "$HostPoolValidation.Name"" -ForegroundColor Green
                }
            } else {  }
        }