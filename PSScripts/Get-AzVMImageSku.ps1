Get-AzVMImagePublisher -Location "West Europe" | Select PublisherName | Where-Object { $_.PublisherName -like '*Windows*' }

# Listing Image Offers
$Publisher = "MicrosoftWindowsDesktop"


Get-AzVMImageOffer -Location "West Europe" -PublisherName $publisher

# Listing Image SKUs
# office-365
# Windows-10
$Offer = "Windows-10"
Get-AzVMImageSku -Location "West Europe" -PublisherName $Publisher -Offer $Offer | Select Skus