Get-AzVMImagePublisher -Location "West Europe" | Select-Object PublisherName | Where-Object { $_.PublisherName -like '*Windows*' }

# Listing Image Offers
$Publisher = "MicrosoftWindowsDesktop"


Get-AzVMImageOffer -Location "West Europe" -PublisherName $publisher

# Listing Image SKUs
# office-365 (multi-session AVD)
# Windows-10 (personal AVD)
$Offer = "office-365"
Get-AzVMImageSku -Location "West Europe" -PublisherName $Publisher -Offer $Offer | Select-Object Skus