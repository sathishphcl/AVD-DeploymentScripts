$Context = New-AzStorageContext -StorageAccountName "ucorpwvdprem" -StorageAccountKey "<StorageAccountKey>"
Get-AzStorageFileHandle -Context $Context -ShareName "fslogixoffice" -Recursive
Close-AzStorageFileHandle -Context $Context -ShareName "fslogixoffice" -CloseAll

# Close specific path
Close-AzStorageFileHandle -Context $Context -ShareName "fslogixoffice" -Path "uenki_S-1-5-21-1951289647-149518158-1539857752-24793/ODFC_uenki.VHDX" -CloseAll